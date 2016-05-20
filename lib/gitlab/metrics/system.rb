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
          mem = 0
          match = File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)

          if match and match[1]
            mem = match[1].to_f * 1024
          end

          mem
        end

        def self.file_descriptor_count
          Dir.glob('/proc/self/fd/*').length
        end

        def self.load_average
          loadavg = File.read('/proc/loadavg').scan(/\d+.\d+/)
          if loadavg && loadavg[0] && loadavg[1] && loadavg[2]
            loadavg[0..2].map { |value| value.to_f }
          else
            [0.0, 0.0, 0.0]
          end
        end
      else
        def self.memory_usage
          0.0
        end

        def self.file_descriptor_count
          0
        end

        def self.load_average
          [0.0, 0.0, 0.0]
        end
      end

      # THREAD_CPUTIME is not supported on OS X
      if Process.const_defined?(:CLOCK_THREAD_CPUTIME_ID)
        def self.cpu_time
          Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :millisecond)
        end
      else
        def self.cpu_time
          Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :millisecond)
        end
      end
    end
  end
end
