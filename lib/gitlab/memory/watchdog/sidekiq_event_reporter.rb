# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class SidekiqEventReporter
        include ::Gitlab::Utils::StrongMemoize

        delegate :threshold_violated, :started, :stopped, :logger, to: :event_reporter

        def initialize(logger: ::Sidekiq.logger)
          @event_reporter = EventReporter.new(logger: logger)
          init_prometheus_metrics
        end

        def strikes_exceeded(monitor_name, labels = {})
          running_jobs = fetch_running_jobs
          labels[:running_jobs] = running_jobs
          increment_worker_counters(running_jobs)

          event_reporter.strikes_exceeded(monitor_name, labels)
        end

        private

        attr_reader :event_reporter

        def fetch_running_jobs
          running_jobs = []
          Gitlab::SidekiqDaemon::Monitor.instance.with_running_jobs do |jobs|
            running_jobs = jobs.map do |jid, job|
              {
                jid: jid,
                worker_class: job[:worker_class].name
              }
            end
          end
          running_jobs
        end

        def increment_worker_counters(running_jobs)
          running_jobs.each do |job|
            @sidekiq_watchdog_running_jobs_counter.increment({ worker_class: job[:worker_class] })
          end
        end

        def init_prometheus_metrics
          @sidekiq_watchdog_running_jobs_counter = ::Gitlab::Metrics.counter(
            :sidekiq_watchdog_running_jobs_total,
            'Current running jobs when limit was reached'
          )
        end
      end
    end
  end
end
