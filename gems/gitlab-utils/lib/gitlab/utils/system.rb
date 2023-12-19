# frozen_string_literal: true

module Gitlab
  module Utils
    # Module for gathering system/process statistics such as the memory usage.
    #
    # This module relies on the /proc filesystem being available. If /proc is
    # not available the methods of this module will be stubbed.
    module System
      extend self

      PROC_STAT_PATH = '/proc/self/stat'
      PROC_STATUS_PATH = '/proc/%s/status'
      PROC_SMAPS_ROLLUP_PATH = '/proc/%s/smaps_rollup'
      PROC_LIMITS_PATH = '/proc/self/limits'
      PROC_FD_GLOB = '/proc/self/fd/*'
      PROC_MEM_INFO = '/proc/meminfo'

      PRIVATE_PAGES_PATTERN = /^(?<type>Private_Clean|Private_Dirty|Private_Hugetlb):\s+(?<value>\d+)/
      PSS_PATTERN = /^Pss:\s+(?<value>\d+)/
      RSS_TOTAL_PATTERN = /^VmRSS:\s+(?<value>\d+)/
      RSS_ANON_PATTERN = /^RssAnon:\s+(?<value>\d+)/
      RSS_FILE_PATTERN = /^RssFile:\s+(?<value>\d+)/
      MAX_OPEN_FILES_PATTERN = /Max open files\s*(?<value>\d+)/
      MEM_TOTAL_PATTERN = /^MemTotal:\s+(?<value>\d+) (?<unit>.+)/

      def summary
        proportional_mem = memory_usage_uss_pss
        {
          version: RUBY_DESCRIPTION,
          gc_stat: GC.stat,
          memory_rss: memory_usage_rss[:total],
          memory_uss: proportional_mem[:uss],
          memory_pss: proportional_mem[:pss],
          time_cputime: cpu_time,
          time_realtime: real_time,
          time_monotonic: monotonic_time
        }
      end

      # Returns the given process' RSS (resident set size) in bytes.
      def memory_usage_rss(pid: 'self')
        results = { total: 0, anon: 0, file: 0 }

        safe_yield_procfile(PROC_STATUS_PATH % pid) do |io|
          io.each_line do |line|
            if (value = parse_metric_value(line, RSS_TOTAL_PATTERN)) > 0
              results[:total] = value.kilobytes
            elsif (value = parse_metric_value(line, RSS_ANON_PATTERN)) > 0
              results[:anon] = value.kilobytes
            elsif (value = parse_metric_value(line, RSS_FILE_PATTERN)) > 0
              results[:file] = value.kilobytes
            end
          end
        end

        results
      end

      # Returns the given process' USS/PSS (unique/proportional set size) in bytes.
      def memory_usage_uss_pss(pid: 'self')
        sum_matches(PROC_SMAPS_ROLLUP_PATH % pid, uss: PRIVATE_PAGES_PATTERN, pss: PSS_PATTERN)
          .transform_values(&:kilobytes)
      end

      def memory_total
        sum_matches(PROC_MEM_INFO, memory_total: MEM_TOTAL_PATTERN)[:memory_total].kilobytes
      end

      def file_descriptor_count
        Dir.glob(PROC_FD_GLOB).length
      end

      def max_open_file_descriptors
        sum_matches(PROC_LIMITS_PATH, max_fds: MAX_OPEN_FILES_PATTERN)[:max_fds]
      end

      def cpu_time
        Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :float_second)
      end

      # Returns the current real time in a given precision.
      #
      # Returns the time as a Float for precision = :float_second.
      def real_time(precision = :float_second)
        Process.clock_gettime(Process::CLOCK_REALTIME, precision)
      end

      # Returns the current monotonic clock time as seconds with microseconds precision.
      #
      # Returns the time as a Float.
      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
      end

      def thread_cpu_time
        # Not all OS kernels are supporting `Process::CLOCK_THREAD_CPUTIME_ID`
        # Refer: https://gitlab.com/gitlab-org/gitlab/issues/30567#note_221765627
        return unless defined?(Process::CLOCK_THREAD_CPUTIME_ID)

        Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :float_second)
      end

      def thread_cpu_duration(start_time)
        end_time = thread_cpu_time
        return unless start_time && end_time

        end_time - start_time
      end

      # Returns the total time the current process has been running in seconds.
      def process_runtime_elapsed_seconds
        # Entry 22 (1-indexed) contains the process `starttime`, see:
        # https://man7.org/linux/man-pages/man5/proc.5.html
        #
        # This value is a fixed timestamp in clock ticks.
        # To obtain an elapsed time in seconds, we divide by the number
        # of ticks per second and subtract from the system uptime.
        start_time_ticks = proc_stat_entries[21].to_f
        clock_ticks_per_second = Etc.sysconf(Etc::SC_CLK_TCK)
        uptime - (start_time_ticks / clock_ticks_per_second)
      end

      private

      # Given a path to a file in /proc and a hash of (metric, pattern) pairs,
      # sums up all values found for those patterns under the respective metric.
      def sum_matches(proc_file, **patterns)
        results = patterns.transform_values { 0 }

        safe_yield_procfile(proc_file) do |io|
          io.each_line do |line|
            patterns.each do |metric, pattern|
              results[metric] += parse_metric_value(line, pattern)
            end
          end
        end

        results
      end

      def parse_metric_value(line, pattern)
        match = line.match(pattern)
        return 0 unless match

        match.named_captures.fetch('value', 0).to_i
      end

      def proc_stat_entries
        safe_yield_procfile(PROC_STAT_PATH) do |io|
          io.read.split(' ')
        end || []
      end

      def safe_yield_procfile(path, &block)
        File.open(path, &block)
      rescue Errno::ENOENT
        # This means the procfile we're reading from did not exist;
        # most likely we're on Darwin.
      end

      # Equivalent to reading /proc/uptime on Linux 2.6+.
      #
      # Returns 0 if not supported, e.g. on Darwin.
      def uptime
        Process.clock_gettime(Process::CLOCK_BOOTTIME)
      rescue NameError
        0
      end
    end
  end
end
