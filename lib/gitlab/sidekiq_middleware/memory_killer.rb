module Gitlab
  module SidekiqMiddleware
    class MemoryKiller
      # Give Sidekiq 15 minutes of grace time after exceeding the RSS limit
      GRACE_TIME = 15 * 60
      # Wait 30 seconds for running jobs to finish during graceful shutdown
      SHUTDOWN_WAIT = 30
      # Create a mutex so that there will be only one thread waiting to shut
      # Sidekiq down
      MUTEX = Mutex.new

      def call(worker, job, queue)
        yield
        current_rss = get_rss

        return unless max_rss > 0 && current_rss > max_rss

        Tread.new do
          # Return if another thread is already waiting to shut Sidekiq down
          return unless MUTEX.try_lock

          Sidekiq.logger.warn "current RSS #{current_rss} exceeds maximum RSS "\
            "#{max_rss}"
          Sidekiq.logger.warn "spawned thread that will shut down PID "\
            "#{Process.pid} in #{grace_time} seconds"
          sleep(grace_time)

          Sidekiq.logger.warn "sending SIGUSR1 to PID #{Process.pid}"
          Process.kill('SIGUSR1', Process.pid)

          Sidekiq.logger.warn "waiting #{shutdown_wait} seconds before sending "\
            "SIGTERM to PID #{Process.pid}"
          sleep(shutdown_wait)

          Sidekiq.logger.warn "sending SIGTERM to PID #{Process.pid}"
          Process.kill('SIGTERM', Process.pid)
        end
      end

      private

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{Process.pid}))
        return 0 unless status.zero?

        output.to_i
      end

      def max_rss
        @max_rss ||= ENV['SIDEKIQ_MAX_RSS'].to_s.to_i
      end

      def shutdown_wait
        @graceful_shutdown_wait ||= (
          ENV['SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT'] || SHUTDOWN_WAIT
        ).to_i
      end

      def grace_time
        @grace_time ||= (
          ENV['SIDEKIQ_MEMORY_KILLER_GRACE_TIME'] || GRACE_TIME
        ).to_i
      end
    end
  end
end
