# frozen_string_literal: true

module Gitlab
  module SidekiqDaemon
    class MemoryKiller < Daemon
      include ::Gitlab::Utils::StrongMemoize

      # Today 64-bit CPU support max 256T memory. It is big enough.
      MAX_MEMORY_KB = 256 * 1024 * 1024 * 1024
      # RSS below `soft_limit_rss` is considered safe
      SOFT_LIMIT_RSS_KB = ENV.fetch('SIDEKIQ_MEMORY_KILLER_MAX_RSS', 2000000).to_i
      # RSS above `hard_limit_rss` will be stopped
      HARD_LIMIT_RSS_KB = ENV.fetch('SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS', MAX_MEMORY_KB).to_i
      # RSS in range (soft_limit_rss, hard_limit_rss) is allowed for GRACE_BALLOON_SECONDS
      GRACE_BALLOON_SECONDS = ENV.fetch('SIDEKIQ_MEMORY_KILLER_GRACE_TIME', 15 * 60).to_i
      # Check RSS every CHECK_INTERVAL_SECONDS, minimum 2 seconds
      CHECK_INTERVAL_SECONDS = [ENV.fetch('SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL', 3).to_i, 2].max
      # Give Sidekiq up to 30 seconds to allow existing jobs to finish after exceeding the limit
      SHUTDOWN_TIMEOUT_SECONDS = ENV.fetch('SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT', 30).to_i
      # Developer/admin should always set `memory_killer_max_memory_growth_kb` explicitly
      # In case not set, default to 300M. This is for extra-safe.
      DEFAULT_MAX_MEMORY_GROWTH_KB = 300_000

      # Phases of memory killer
      PHASE = {
        running: 1,
        above_soft_limit: 2,
        stop_fetching_new_jobs: 3,
        shutting_down: 4,
        killing_sidekiq: 5
      }.freeze

      def initialize
        super

        @enabled = true
        @metrics = init_metrics
      end

      private

      def init_metrics
        {
          sidekiq_current_rss:                  ::Gitlab::Metrics.gauge(:sidekiq_current_rss, 'Current RSS of Sidekiq Worker'),
          sidekiq_memory_killer_soft_limit_rss: ::Gitlab::Metrics.gauge(:sidekiq_memory_killer_soft_limit_rss, 'Current soft_limit_rss of Sidekiq Worker'),
          sidekiq_memory_killer_hard_limit_rss: ::Gitlab::Metrics.gauge(:sidekiq_memory_killer_hard_limit_rss, 'Current hard_limit_rss of Sidekiq Worker'),
          sidekiq_memory_killer_phase:          ::Gitlab::Metrics.gauge(:sidekiq_memory_killer_phase, 'Current phase of Sidekiq Worker')
        }
      end

      def refresh_state(phase)
        @phase = PHASE.fetch(phase)
        @current_rss = get_rss
        @soft_limit_rss = get_soft_limit_rss
        @hard_limit_rss = get_hard_limit_rss

        # track the current state as prometheus gauges
        @metrics[:sidekiq_memory_killer_phase].set({}, @phase)
        @metrics[:sidekiq_current_rss].set({}, @current_rss)
        @metrics[:sidekiq_memory_killer_soft_limit_rss].set({}, @soft_limit_rss)
        @metrics[:sidekiq_memory_killer_hard_limit_rss].set({}, @hard_limit_rss)
      end

      def run_thread
        Sidekiq.logger.info(
          class: self.class.to_s,
          action: 'start',
          pid: pid,
          message: 'Starting Gitlab::SidekiqDaemon::MemoryKiller Daemon'
        )

        while enabled?
          begin
            sleep(CHECK_INTERVAL_SECONDS)
            restart_sidekiq unless rss_within_range?
          rescue StandardError => e
            log_exception(e, __method__)
          rescue Exception => e # rubocop:disable Lint/RescueException
            log_exception(e, __method__ )
            raise e
          end
        end
      ensure
        Sidekiq.logger.warn(
          class: self.class.to_s,
          action: 'stop',
          pid: pid,
          message: 'Stopping Gitlab::SidekiqDaemon::MemoryKiller Daemon'
        )
      end

      def log_exception(exception, method)
        Sidekiq.logger.warn(
          class: self.class.to_s,
          pid: pid,
          message: "Exception from #{method}: #{exception.message}"
        )
      end

      def stop_working
        @enabled = false
      end

      def enabled?
        @enabled
      end

      def restart_sidekiq
        # Tell Sidekiq to stop fetching new jobs
        # We first SIGNAL and then wait given time
        # We also monitor a number of running jobs and allow to restart early
        refresh_state(:stop_fetching_new_jobs)
        signal_and_wait(SHUTDOWN_TIMEOUT_SECONDS, 'SIGTSTP', 'stop fetching new jobs')
        return unless enabled?

        # Tell sidekiq to restart itself
        # Keep extra safe to wait `Sidekiq.options[:timeout] + 2` seconds before SIGKILL
        refresh_state(:shutting_down)
        signal_and_wait(Sidekiq.options[:timeout] + 2, 'SIGTERM', 'gracefully shut down')
        return unless enabled?

        # Ideally we should never reach this condition
        # Wait for Sidekiq to shutdown gracefully, and kill it if it didn't
        # Kill the whole pgroup, so we can be sure no children are left behind
        refresh_state(:killing_sidekiq)
        signal_pgroup('SIGKILL', 'die')
      end

      def rss_within_range?
        refresh_state(:running)

        deadline = Gitlab::Metrics::System.monotonic_time + GRACE_BALLOON_SECONDS.seconds
        loop do
          return true unless enabled?

          # RSS go above hard limit should trigger forcible shutdown right away
          break if @current_rss > @hard_limit_rss

          # RSS go below the soft limit
          return true if @current_rss < @soft_limit_rss

          # RSS did not go below the soft limit within deadline, restart
          break if Gitlab::Metrics::System.monotonic_time > deadline

          sleep(CHECK_INTERVAL_SECONDS)

          refresh_state(:above_soft_limit)
        end

        # There are two chances to break from loop:
        #   - above hard limit, or
        #   - above soft limit after deadline
        # When `above hard limit`, it immediately go to `stop_fetching_new_jobs`
        # So ignore `above hard limit` and always set `above_soft_limit` here
        refresh_state(:above_soft_limit)
        log_rss_out_of_range(@current_rss, @hard_limit_rss, @soft_limit_rss)

        false
      end

      def log_rss_out_of_range(current_rss, hard_limit_rss, soft_limit_rss)
        Sidekiq.logger.warn(
          class: self.class.to_s,
          pid: pid,
          message: 'Sidekiq worker RSS out of range',
          current_rss: current_rss,
          hard_limit_rss: hard_limit_rss,
          soft_limit_rss: soft_limit_rss,
          reason: out_of_range_description(current_rss, hard_limit_rss, soft_limit_rss)
        )
      end

      def out_of_range_description(rss, hard_limit, soft_limit)
        if rss > hard_limit
          "current_rss(#{rss}) > hard_limit_rss(#{hard_limit})"
        else
          "current_rss(#{rss}) > soft_limit_rss(#{soft_limit}) longer than GRACE_BALLOON_SECONDS(#{GRACE_BALLOON_SECONDS})"
        end
      end

      def get_rss
        output, status = Gitlab::Popen.popen(%W(ps -o rss= -p #{pid}), Rails.root.to_s)
        return 0 unless status&.zero?

        output.to_i
      end

      def get_soft_limit_rss
        SOFT_LIMIT_RSS_KB + rss_increase_by_jobs
      end

      def get_hard_limit_rss
        HARD_LIMIT_RSS_KB
      end

      def signal_and_wait(time, signal, explanation)
        Sidekiq.logger.warn(
          class: self.class.to_s,
          pid: pid,
          signal: signal,
          explanation: explanation,
          wait_time: time,
          message: "Sending signal and waiting"
        )
        Process.kill(signal, pid)

        deadline = Gitlab::Metrics::System.monotonic_time + time

        # we try to finish as early as all jobs finished
        # so we retest that in loop
        sleep(CHECK_INTERVAL_SECONDS) while enabled? && any_jobs? && Gitlab::Metrics::System.monotonic_time < deadline
      end

      def signal_pgroup(signal, explanation)
        if Process.getpgrp == pid
          pid_or_pgrp_str = 'PGRP'
          pid_to_signal = 0
        else
          pid_or_pgrp_str = 'PID'
          pid_to_signal = pid
        end

        Sidekiq.logger.warn(
          class: self.class.to_s,
          signal: signal,
          pid: pid,
          message: "sending Sidekiq worker #{pid_or_pgrp_str}-#{pid} #{signal} (#{explanation})"
        )
        Process.kill(signal, pid_to_signal)
      end

      def rss_increase_by_jobs
        Gitlab::SidekiqDaemon::Monitor.instance.jobs_mutex.synchronize do
          Gitlab::SidekiqDaemon::Monitor.instance.jobs.sum do |job|
            rss_increase_by_job(job)
          end
        end
      end

      def rss_increase_by_job(job)
        memory_growth_kb = get_job_options(job, 'memory_killer_memory_growth_kb', 0).to_i
        max_memory_growth_kb = get_job_options(job, 'memory_killer_max_memory_growth_kb', DEFAULT_MAX_MEMORY_GROWTH_KB).to_i

        return 0 if memory_growth_kb == 0

        time_elapsed = [Gitlab::Metrics::System.monotonic_time - job[:started_at], 0].max
        [memory_growth_kb * time_elapsed, max_memory_growth_kb].min
      end

      def get_job_options(job, key, default)
        job[:worker_class].sidekiq_options.fetch(key, default)
      rescue StandardError
        default
      end

      def pid
        Process.pid
      end

      def any_jobs?
        Gitlab::SidekiqDaemon::Monitor.instance.jobs.any?
      end
    end
  end
end
