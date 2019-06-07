# frozen_string_literal: true

module Gitlab
  module Metrics
    # Module for gathering system/process statistics such as the memory usage.
    #
    # This module relies on the /proc filesystem being available. If /proc is
    # not available the methods of this module will be stubbed.
    module System
      if File.exist?('/proc')
        # Returns the current process' memory usage in bytes.
        def self.memory_usage
          mem   = 0
          match = File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)

          if match && match[1]
            mem = match[1].to_f * 1024
          end

          mem
        end

        def self.file_descriptor_count
          Dir.glob('/proc/self/fd/*').length
        end

        def self.max_open_file_descriptors
          match = File.read('/proc/self/limits').match(/Max open files\s*(\d+)/)

          return unless match && match[1]

          match[1].to_i
        end

        def self.process_start_time
          fields = File.read('/proc/self/stat').split

          # fields[21] is linux proc stat field "(22) starttime".
          # The value is expressed in clock ticks, divide by clock ticks for seconds.
          ( fields[21].to_i || 0 ) / clk_tck
        end
      else
        def self.memory_usage
          0.0
        end

        def self.file_descriptor_count
          0
        end

        def self.max_open_file_descriptors
          0
        end

        def self.process_start_time
          0
        end
      end

      # THREAD_CPUTIME is not supported on OS X
      if Process.const_defined?(:CLOCK_THREAD_CPUTIME_ID)
        def self.cpu_time
          Process
            .clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :float_second)
        end
      else
        def self.cpu_time
          Process
            .clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :float_second)
        end
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

      def self.clk_tck
        @clk_tck ||= `getconf CLK_TCK`.to_i
      end
    end
  end
end
