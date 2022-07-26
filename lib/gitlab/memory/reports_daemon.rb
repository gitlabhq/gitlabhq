# frozen_string_literal: true

module Gitlab
  module Memory
    class ReportsDaemon < Daemon
      DEFAULT_SLEEP_S = 7200 # 2 hours
      DEFAULT_SLEEP_MAX_DELTA_S = 600 # 0..10 minutes
      DEFAULT_SLEEP_BETWEEN_REPORTS_S = 120 # 2 minutes

      DEFAULT_REPORTS_PATH = '/tmp'

      def initialize(**options)
        super

        @alive = true

        @sleep_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_S']&.to_i || DEFAULT_SLEEP_S
        @sleep_max_delta_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S']&.to_i || DEFAULT_SLEEP_MAX_DELTA_S
        @sleep_between_reports_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_BETWEEN_REPORTS_S']&.to_i || DEFAULT_SLEEP_BETWEEN_REPORTS_S

        @reports_path =
          ENV["GITLAB_DIAGNOSTIC_REPORTS_PATH"] || DEFAULT_REPORTS_PATH

        @reports = [Gitlab::Memory::Reports::JemallocStats.new(reports_path: reports_path)]

        init_prometheus_metrics
      end

      attr_reader :sleep_s, :sleep_max_delta_s, :sleep_between_reports_s, :reports_path

      def run_thread
        while alive
          sleep interval_with_jitter

          reports.select(&:active?).each do |report|
            tms = Benchmark.measure do
              report.run
            end

            log_report(report_label(report), tms)
            @report_duration_counter.increment({ report: report_label(report) }, tms.real)

            sleep sleep_between_reports_s
          end
        end
      end

      private

      attr_reader :alive, :reports

      # Returns the sleep interval with a random adjustment.
      # The random adjustment is put in place to ensure continued availability.
      def interval_with_jitter
        sleep_s + rand(sleep_max_delta_s)
      end

      def log_report(report_label, tms)
        Gitlab::AppLogger.info(
          message: 'finished',
          pid: $$,
          worker_id: worker_id,
          perf_report: report_label,
          duration_s: tms.real.round(2),
          cpu_s: tms.utime.round(2),
          sys_cpu_s: tms.stime.round(2)
        )
      end

      def worker_id
        ::Prometheus::PidProvider.worker_id
      end

      def report_label(report)
        report.class.to_s.demodulize.underscore
      end

      def stop_working
        @alive = false
      end

      def init_prometheus_metrics
        default_labels = { pid: worker_id }

        @report_duration_counter = Gitlab::Metrics.counter(
          :gitlab_diag_report_duration_seconds_total,
          'Total time elapsed for running diagnostic report',
          default_labels
        )
      end
    end
  end
end
