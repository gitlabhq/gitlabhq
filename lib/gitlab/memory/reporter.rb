# frozen_string_literal: true

module Gitlab
  module Memory
    class Reporter
      def initialize
        @worker_uuid = SecureRandom.uuid

        init_prometheus_metrics
      end

      def run_report(report)
        start_monotonic_time = Gitlab::Metrics::System.monotonic_time
        start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time

        file_path = report.run(report_id)

        cpu_s = Gitlab::Metrics::System.thread_cpu_duration(start_thread_cpu_time)
        duration_s = Gitlab::Metrics::System.monotonic_time - start_monotonic_time

        log_report(name: report.name, cpu_s: cpu_s, duration_s: duration_s, size: file_size(file_path))

        @report_duration_counter.increment({ report: report.name }, duration_s)
      end

      private

      def log_report(name:, duration_s:, cpu_s:, size:)
        Gitlab::AppLogger.info(
          message: 'finished',
          pid: $$,
          worker_id: worker_id,
          perf_report: name,
          duration_s: duration_s.round(2),
          cpu_s: cpu_s.round(2),
          perf_report_size_bytes: size,
          perf_report_worker_uuid: @worker_uuid
        )
      end

      def report_id
        [worker_id, @worker_uuid].join(".")
      end

      def worker_id
        ::Prometheus::PidProvider.worker_id
      end

      def file_size(file_path)
        File.size(file_path.to_s)
      rescue Errno::ENOENT
        0
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
