module Gitlab
  module SidekiqMiddleware
    class MemoryKiller
      # Wait 30 seconds for running jobs to finish during graceful shutdown
      GRACEFUL_SHUTDOWN_WAIT = 30

      def call(worker, job, queue)
        yield
        current_rss = get_rss
        return unless max_rss > 0 && current_rss > max_rss

        Sidekiq.logger.warn "current RSS #{current_rss} exceeds maximum RSS "\
         "#{max_rss}"
        Sidekiq.logger.warn "sending SIGUSR1 to PID #{Process.pid}"
        Process.kill('SIGUSR1', Process.pid)

        Sidekiq.logger.warn "spawning thread that will send SIGTERM to PID "\
          "#{Process.pid} in #{graceful_shutdown_wait} seconds"
        Thread.new do
          sleep(graceful_shutdown_wait)
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

      def graceful_shutdown_wait
        @graceful_shutdown_wait ||= (
          ENV['SIDEKIQ_GRACEFUL_SHUTDOWN_WAIT'] || GRACEFUL_SHUTDOWN_WAIT
        ).to_i
      end
    end
  end
end
