# frozen_string_literal: true

module Gitlab
  # Chaos methods for GitLab.
  # See https://docs.gitlab.com/ee/development/chaos_endpoints.html for more details.
  class Chaos
    # leak_mem will retain the specified amount of memory and sleep.
    # On return, the memory will be released.
    def self.leak_mem(memory_mb, duration_s)
      start_time = Time.now

      retainer = []
      # Add `n` 1mb chunks of memory to the retainer array
      memory_mb.times { retainer << "x" * 1.megabyte }

      duration_left = [start_time + duration_s - Time.now, 0].max
      Kernel.sleep(duration_left)
    end

    # cpu_spin will consume all CPU on a single core for the specified duration
    def self.cpu_spin(duration_s)
      return unless Gitlab::Metrics::System.thread_cpu_time

      expected_end_time = Gitlab::Metrics::System.thread_cpu_time + duration_s

      rand while Gitlab::Metrics::System.thread_cpu_time < expected_end_time
    end

    # db_spin will query the database in a tight loop for the specified duration
    def self.db_spin(duration_s, interval_s)
      expected_end_time = Time.now + duration_s

      while Time.now < expected_end_time
        ApplicationRecord.connection.execute("SELECT 1")

        end_interval_time = Time.now + [duration_s, interval_s].min
        rand while Time.now < end_interval_time
      end
    end

    # sleep will sleep for the specified duration
    def self.sleep(duration_s)
      Kernel.sleep(duration_s)
    end

    # Kill will send the given signal to the current process.
    def self.kill(signal)
      Process.kill(signal, Process.pid)
    end

    def self.run_gc
      # Tenure any live objects from young-gen to old-gen
      4.times { GC.start(full_mark: false) }
      # Run a full mark-and-sweep collection
      GC.start
      GC.stat
    end
  end
end
