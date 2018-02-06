module Gitlab
  module SidekiqMiddleware
    class MemoryKiller
      # Default the RSS limit to 0, meaning the MemoryKiller is disabled
      MAX_RSS = (ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS'] || 0).to_s.to_i
      # Give Sidekiq 15 minutes of grace time after exceeding the RSS limit
      GRACE_TIME = (ENV['SIDEKIQ_MEMORY_KILLER_GRACE_TIME'] || 15 * 60).to_s.to_i
      # Wait 30 seconds for running jobs to finish during graceful shutdown
      SHUTDOWN_WAIT = (ENV['SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT'] || 30).to_s.to_i

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

          Sidekiq.logger.warn "Sidekiq worker PID-#{pid} current RSS #{current_rss}"\
            " exceeds maximum RSS #{MAX_RSS} after finishing job #{worker.class} JID-#{job['jid']}"
          Sidekiq.logger.warn "Sidekiq worker PID-#{pid} will stop fetching new jobs in #{GRACE_TIME} seconds, and will be shut down #{SHUTDOWN_WAIT} seconds later"

          # Wait `GRACE_TIME` to give the memory intensive job time to finish.
          # Then, tell Sidekiq to stop fetching new jobs.
          wait_and_signal(GRACE_TIME, 'SIGSTP', 'stop fetching new jobs')

          # Wait `SHUTDOWN_WAIT` to give already fetched jobs time to finish.
          # Then, tell Sidekiq to gracefully shut down by giving jobs a few more
          # moments to finish, killing and requeuing them if they didn't, and
          # then terminating itself.
          wait_and_signal(SHUTDOWN_WAIT, 'SIGTERM', 'gracefully shut down')

          # Wait for Sidekiq to shutdown gracefully, and kill it if it didn't.
          wait_and_signal(Sidekiq.options[:timeout] + 2, 'SIGKILL', 'die')
        end
      end

      private

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{pid}), Rails.root.to_s)
        return 0 unless status.zero?

        output.to_i
      end

      def wait_and_signal(time, signal, explanation)
        Sidekiq.logger.warn "waiting #{time} seconds before sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})"
        sleep(time)

        Sidekiq.logger.warn "sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})"
        Process.kill(signal, pid)
      end

      def pid
        Process.pid
      end
    end
  end
end
