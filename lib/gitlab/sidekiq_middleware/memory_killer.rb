# frozen_string_literal: true

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

      attr_reader :worker

      def call(worker, job, queue)
        yield

        @worker = worker
        current_rss = get_rss

        return unless MAX_RSS > 0 && current_rss > MAX_RSS

        Thread.new do
          # Return if another thread is already waiting to shut Sidekiq down
          next unless MUTEX.try_lock

          warn("Sidekiq worker PID-#{pid} current RSS #{current_rss}"\
               " exceeds maximum RSS #{MAX_RSS} after finishing job #{worker.class} JID-#{job['jid']}")

          warn("Sidekiq worker PID-#{pid} will stop fetching new jobs"\
               " in #{GRACE_TIME} seconds, and will be shut down #{SHUTDOWN_WAIT} seconds later")

          # Wait `GRACE_TIME` to give the memory intensive job time to finish.
          # Then, tell Sidekiq to stop fetching new jobs.
          wait_and_signal(GRACE_TIME, 'SIGTSTP', 'stop fetching new jobs')

          # Wait `SHUTDOWN_WAIT` to give already fetched jobs time to finish.
          # Then, tell Sidekiq to gracefully shut down by giving jobs a few more
          # moments to finish, killing and requeuing them if they didn't, and
          # then terminating itself. Sidekiq will replicate the TERM to all its
          # children if it can.
          wait_and_signal(SHUTDOWN_WAIT, 'SIGTERM', 'gracefully shut down')

          # Wait for Sidekiq to shutdown gracefully, and kill it if it didn't.
          # Kill the whole pgroup, so we can be sure no children are left behind
          wait_and_signal_pgroup(Sidekiq.options[:timeout] + 2, 'SIGKILL', 'die')
        end
      end

      private

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{pid}), Rails.root.to_s)
        return 0 unless status.zero?

        output.to_i
      end

      # If this sidekiq process is pgroup leader, signal to the whole pgroup
      def wait_and_signal_pgroup(time, signal, explanation)
        return wait_and_signal(time, signal, explanation) unless Process.getpgrp == pid

        warn("waiting #{time} seconds before sending Sidekiq worker PGRP-#{pid} #{signal} (#{explanation})", signal: signal)
        sleep(time)

        warn("sending Sidekiq worker PGRP-#{pid} #{signal} (#{explanation})", signal: signal)
        Process.kill(signal, 0)
      end

      def wait_and_signal(time, signal, explanation)
        warn("waiting #{time} seconds before sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})", signal: signal)
        sleep(time)

        warn("sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})", signal: signal)
        Process.kill(signal, pid)
      end

      def pid
        Process.pid
      end

      def warn(message, signal: nil)
        Sidekiq.logger.warn(class: worker.class, pid: pid, signal: signal, message: message)
      end
    end
  end
end
