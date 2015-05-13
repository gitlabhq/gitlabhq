module Gitlab
  module SidekiqMiddleware
    class MemoryKiller
      # Default the RSS limit to 0, meaning the MemoryKiller is disabled
      MAX_RSS = (ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS'] || 0).to_s.to_i
      # Give Sidekiq 15 minutes of grace time after exceeding the RSS limit
      GRACE_TIME = (ENV['SIDEKIQ_MEMORY_KILLER_GRACE_TIME'] || 15 * 60).to_s.to_i
      # Wait 30 seconds for running jobs to finish during graceful shutdown
      SHUTDOWN_WAIT = (ENV['SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT'] || 30).to_s.to_i
      SHUTDOWN_SIGNAL = (ENV['SIDEKIQ_MEMORY_KILLER_SHUTDOWN_SIGNAL'] || 'SIGKILL').to_s

      # Create a mutex used to ensure there will be only one thread waiting to
      # shut Sidekiq down
      MUTEX = Mutex.new

      def call(worker, job, queue)
        yield
        current_rss = get_rss

        return unless MAX_RSS > 0 && current_rss > MAX_RSS

        Thread.new do
          # Return if another thread is already waiting to shut Sidekiq down
          return unless MUTEX.try_lock

          Sidekiq.logger.warn "current RSS #{current_rss} exceeds maximum RSS "\
            "#{MAX_RSS}"
          Sidekiq.logger.warn "this thread will shut down PID #{Process.pid} "\
            "in #{GRACE_TIME} seconds"
          sleep(GRACE_TIME)

          Sidekiq.logger.warn "sending SIGUSR1 to PID #{Process.pid}"
          Process.kill('SIGUSR1', Process.pid)

          Sidekiq.logger.warn "waiting #{SHUTDOWN_WAIT} seconds before sending "\
            "#{SHUTDOWN_SIGNAL} to PID #{Process.pid}"
          sleep(SHUTDOWN_WAIT)

          Sidekiq.logger.warn "sending #{SHUTDOWN_SIGNAL} to PID #{Process.pid}"
          Process.kill(SHUTDOWN_SIGNAL, Process.pid)
        end
      end

      private

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{Process.pid}))
        return 0 unless status.zero?

        output.to_i
      end
    end
  end
end
