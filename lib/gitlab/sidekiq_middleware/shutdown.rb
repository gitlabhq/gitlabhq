require 'mutex_m'

module Gitlab
  module SidekiqMiddleware
    class Shutdown
      extend Mutex_m

      # Default the RSS limit to 0, meaning the MemoryKiller is disabled
      MAX_RSS = (ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS'] || 0).to_s.to_i
      # Give Sidekiq 15 minutes of grace time after exceeding the RSS limit
      GRACE_TIME = (ENV['SIDEKIQ_MEMORY_KILLER_GRACE_TIME'] || 15 * 60).to_s.to_i
      # Wait 30 seconds for running jobs to finish during graceful shutdown
      SHUTDOWN_WAIT = (ENV['SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT'] || 30).to_s.to_i

      # This exception can be used to request that the middleware start shutting down Sidekiq
      WantShutdown = Class.new(StandardError)

      ShutdownWithoutRaise = Class.new(WantShutdown)
      private_constant :ShutdownWithoutRaise

      # For testing only, to avoid race conditions (?) in Rspec mocks.
      attr_reader :trace

      # We store the shutdown thread in a class variable to ensure that there
      # can be only one shutdown thread in the process.
      def self.create_shutdown_thread
        mu_synchronize do
          break unless @shutdown_thread.nil?

          @shutdown_thread = Thread.new { yield }
        end
      end

      # For testing only: so we can wait for the shutdown thread to finish.
      def self.shutdown_thread
        mu_synchronize { @shutdown_thread }
      end

      # For testing only: so that we can reset the global state before each test.
      def self.clear_shutdown_thread
        mu_synchronize { @shutdown_thread = nil }
      end

      def initialize
        @trace = Queue.new if Rails.env.test?
      end

      def call(worker, job, queue)
        shutdown_exception = nil

        begin
          yield
          check_rss!
        rescue WantShutdown => ex
          shutdown_exception = ex
        end

        return unless shutdown_exception

        self.class.create_shutdown_thread do
          do_shutdown(worker, job, shutdown_exception)
        end

        raise shutdown_exception unless shutdown_exception.is_a?(ShutdownWithoutRaise)
      end

      private

      def do_shutdown(worker, job, shutdown_exception)
        Sidekiq.logger.warn "Sidekiq worker PID-#{pid} shutting down because of #{shutdown_exception} after job "\
          "#{worker.class} JID-#{job['jid']}"
        Sidekiq.logger.warn "Sidekiq worker PID-#{pid} will stop fetching new jobs in #{GRACE_TIME} seconds, and will be shut down #{SHUTDOWN_WAIT} seconds later"

        # Wait `GRACE_TIME` to give the memory intensive job time to finish.
        # Then, tell Sidekiq to stop fetching new jobs.
        wait_and_signal(GRACE_TIME, 'SIGTSTP', 'stop fetching new jobs')

        # Wait `SHUTDOWN_WAIT` to give already fetched jobs time to finish.
        # Then, tell Sidekiq to gracefully shut down by giving jobs a few more
        # moments to finish, killing and requeuing them if they didn't, and
        # then terminating itself.
        wait_and_signal(SHUTDOWN_WAIT, 'SIGTERM', 'gracefully shut down')

        # Wait for Sidekiq to shutdown gracefully, and kill it if it didn't.
        wait_and_signal(Sidekiq.options[:timeout] + 2, 'SIGKILL', 'die')
      end

      def check_rss!
        return unless MAX_RSS > 0

        current_rss = get_rss
        return unless current_rss > MAX_RSS

        raise ShutdownWithoutRaise.new("current RSS #{current_rss} exceeds maximum RSS #{MAX_RSS}")
      end

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{pid}), Rails.root.to_s)
        return 0 unless status.zero?

        output.to_i
      end

      def wait_and_signal(time, signal, explanation)
        Sidekiq.logger.warn "waiting #{time} seconds before sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})"
        sleep(time)

        Sidekiq.logger.warn "sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})"
        kill(signal, pid)
      end

      def pid
        Process.pid
      end

      def sleep(time)
        if Rails.env.test?
          @trace << [:sleep, time]
        else
          Kernel.sleep(time)
        end
      end

      def kill(signal, pid)
        if Rails.env.test?
          @trace << [:kill, signal, pid]
        else
          Process.kill(signal, pid)
        end
      end
    end
  end
end
