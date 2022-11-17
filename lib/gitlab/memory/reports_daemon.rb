# frozen_string_literal: true

module Gitlab
  module Memory
    class ReportsDaemon < Daemon
      DEFAULT_SLEEP_S = 7200 # 2 hours
      DEFAULT_SLEEP_MAX_DELTA_S = 600 # 0..10 minutes
      DEFAULT_SLEEP_BETWEEN_REPORTS_S = 120 # 2 minutes

      DEFAULT_REPORTS_PATH = Dir.tmpdir

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

        # Set unique uuid for every ReportsDaemon instance.
        # Because we spawn a single instance of it per process, it will also uniquely identify the worker.
        # Unlike `::Prometheus::PidProvider.worker_id`, this uuid will remain unique across all Puma clusters.
        # This way, we can identify reports that were produced from the same worker process during its lifetime.
        @worker_uuid = SecureRandom.uuid

        @reports = [
          Gitlab::Memory::Reports::JemallocStats.new(reports_path: reports_path, filename_label: filename_label)
        ]

        init_prometheus_metrics
      end

      attr_reader :sleep_s, :sleep_max_delta_s, :sleep_between_reports_s, :reports_path

      def run_thread
        while alive
          sleep interval_with_jitter

          reports.select(&:active?).each do |report|
            start_monotonic_time = Gitlab::Metrics::System.monotonic_time
            start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time

            file_path = report.run

            cpu_s = Gitlab::Metrics::System.thread_cpu_duration(start_thread_cpu_time)
            duration_s = Gitlab::Metrics::System.monotonic_time - start_monotonic_time

            log_report(label: report_label(report), cpu_s: cpu_s, duration_s: duration_s, size: file_size(file_path))
            @report_duration_counter.increment({ report: report_label(report) }, duration_s)

            sleep sleep_between_reports_s
          end
        end
      end

      private

      attr_reader :alive, :reports, :worker_uuid

      def filename_label
        [worker_id, worker_uuid].join(".")
      end

      # Returns the sleep interval with a random adjustment.
      # The random adjustment is put in place to ensure continued availability.
      def interval_with_jitter
        sleep_s + rand(sleep_max_delta_s)
      end

      def log_report(label:, duration_s:, cpu_s:, size:)
        Gitlab::AppLogger.info(
          message: 'finished',
          pid: $$,
          worker_id: worker_id,
          perf_report: label,
          duration_s: duration_s.round(2),
          cpu_s: cpu_s.round(2),
          perf_report_size_bytes: size,
          perf_report_worker_uuid: worker_uuid
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

      def file_size(file_path)
        File.size(file_path.to_s)
      rescue Errno::ENOENT
        0
      end
    end
  end
end
