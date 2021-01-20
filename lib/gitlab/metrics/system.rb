# frozen_string_literal: true

module Gitlab
  module Metrics
    # Module for gathering system/process statistics such as the memory usage.
    #
    # This module relies on the /proc filesystem being available. If /proc is
    # not available the methods of this module will be stubbed.
    module System
      PROC_STATUS_PATH = '/proc/self/status'
      PROC_SMAPS_ROLLUP_PATH = '/proc/self/smaps_rollup'
      PROC_LIMITS_PATH = '/proc/self/limits'
      PROC_FD_GLOB = '/proc/self/fd/*'

      PRIVATE_PAGES_PATTERN = /^(Private_Clean|Private_Dirty|Private_Hugetlb):\s+(?<value>\d+)/.freeze
      PSS_PATTERN = /^Pss:\s+(?<value>\d+)/.freeze
      RSS_PATTERN = /VmRSS:\s+(?<value>\d+)/.freeze
      MAX_OPEN_FILES_PATTERN = /Max open files\s*(?<value>\d+)/.freeze

      def self.summary
        proportional_mem = memory_usage_uss_pss
        {
          version: RUBY_DESCRIPTION,
          gc_stat: GC.stat,
          memory_rss: memory_usage_rss,
          memory_uss: proportional_mem[:uss],
          memory_pss: proportional_mem[:pss],
          time_cputime: cpu_time,
          time_realtime: real_time,
          time_monotonic: monotonic_time
        }
      end

      # Returns the current process' RSS (resident set size) in bytes.
      def self.memory_usage_rss
        sum_matches(PROC_STATUS_PATH, rss: RSS_PATTERN)[:rss].kilobytes
      end

      # Returns the current process' USS/PSS (unique/proportional set size) in bytes.
      def self.memory_usage_uss_pss
        sum_matches(PROC_SMAPS_ROLLUP_PATH, uss: PRIVATE_PAGES_PATTERN, pss: PSS_PATTERN)
          .transform_values(&:kilobytes)
      end

      def self.file_descriptor_count
        Dir.glob(PROC_FD_GLOB).length
      end

      def self.max_open_file_descriptors
        sum_matches(PROC_LIMITS_PATH, max_fds: MAX_OPEN_FILES_PATTERN)[:max_fds]
      end

      def self.cpu_time
        Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :float_second)
      end

      # Returns the current real time in a given precision.
      #
      # Returns the time as a Float for precision = :float_second.
      def self.real_time(precision = :float_second)
        Process.clock_gettime(Process::CLOCK_REALTIME, precision)
      end

      # Returns the current monotonic clock time as seconds with microseconds precision.
      #
      # Returns the time as a Float.
      def self.monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
      end

      def self.thread_cpu_time
        # Not all OS kernels are supporting `Process::CLOCK_THREAD_CPUTIME_ID`
        # Refer: https://gitlab.com/gitlab-org/gitlab/issues/30567#note_221765627
        return unless defined?(Process::CLOCK_THREAD_CPUTIME_ID)

        Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :float_second)
      end

      def self.thread_cpu_duration(start_time)
        end_time = thread_cpu_time
        return unless start_time && end_time

        end_time - start_time
      end

      # Given a path to a file in /proc and a hash of (metric, pattern) pairs,
      # sums up all values found for those patterns under the respective metric.
      def self.sum_matches(proc_file, **patterns)
        results = patterns.transform_values { 0 }

        begin
          File.foreach(proc_file) do |line|
            patterns.each do |metric, pattern|
              match = line.match(pattern)
              value = match&.named_captures&.fetch('value', 0)
              results[metric] += value.to_i
            end
          end
        rescue Errno::ENOENT
          # This means the procfile we're reading from did not exist;
          # this is safe to ignore, since we initialize each metric to 0
        end

        results
      end
    end
  end
end
