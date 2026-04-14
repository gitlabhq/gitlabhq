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
      memory_mb.times { retainer << ("x" * 1.megabyte) }

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
      expected_end_time = Time.current + duration_s

      while expected_end_time.future?
        ApplicationRecord.connection.execute("SELECT 1")

        end_interval_time = Time.current + [duration_s, interval_s].min
        rand while end_interval_time.future?
      end
    end

    # sleep will sleep for the specified duration
    def self.sleep(duration_s)
      Kernel.sleep(duration_s)
    end

    def self.db_sleep(duration_s)
      raise ArgumentError, "Duration must be a positive number" unless duration_s.is_a?(Numeric) && duration_s > 0
      raise ArgumentError, "Duration cannot exceed 300 seconds" if duration_s > 300

      ApplicationRecord.connection.execute(ApplicationRecord.sanitize_sql_array(["SELECT PG_SLEEP(?)", duration_s]))
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

    # feature_flag_test introduces chaos when the `ebonet_chaos_tests` feature flag
    # is enabled. It has a 20% chance of raising a 500 error (via the endpoint) and
    # a 20% chance of adding 300ms of latency. Used to demonstrate feature flag
    # observability by comparing request metrics with the flag on vs. off.
    #
    # `endpoint` is the Grape endpoint instance, used to call `error!` for HTTP 500s.
    def self.feature_flag_test(endpoint)
      roll = Kernel.rand

      if roll < 0.2
        endpoint.error!('Internal Server Error', 500)
      elsif roll < 0.4
        Kernel.sleep(0.3)
      end
    end
  end
end
