# frozen_string_literal: true

module Gitlab
  module Memory
    class Reporter
      COMPRESS_CMD = %w[gzip --fast].freeze

      attr_reader :reports_path

      def initialize(reports_path: nil, logger: Gitlab::AppLogger)
        @reports_path = reports_path || ENV["GITLAB_DIAGNOSTIC_REPORTS_PATH"] || Dir.mktmpdir
        @logger = logger

        @worker_id = ::Prometheus::PidProvider.worker_id
        @worker_uuid = SecureRandom.uuid

        init_prometheus_metrics
      end

      def run_report(report)
        return false unless report.active?

        @logger.info(
          log_labels(
            message: 'started',
            perf_report: report.name
          ))

        start_monotonic_time = ::Gitlab::Metrics::System.monotonic_time
        start_thread_cpu_time = ::Gitlab::Metrics::System.thread_cpu_time

        report_file = store_report(report)

        cpu_s = ::Gitlab::Metrics::System.thread_cpu_duration(start_thread_cpu_time)
        duration_s = ::Gitlab::Metrics::System.monotonic_time - start_monotonic_time

        @logger.info(
          log_labels(
            message: 'finished',
            perf_report: report.name,
            cpu_s: cpu_s.round(2),
            duration_s: duration_s.round(2),
            perf_report_file: report_file,
            perf_report_size_bytes: file_size(report_file)
          ))

        @report_duration_counter.increment({ report: report.name }, duration_s)

        true
      rescue StandardError => e
        @logger.error(
          log_labels(
            message: 'failed',
            perf_report: report.name,
            error: e.inspect
          ))

        false
      end

      private

      def store_report(report)
        # Store report in tmp subdir while it is still streaming.
        # This will clearly separate finished reports from the files we are still writing to.
        tmp_dir = File.join(@reports_path, 'tmp')
        FileUtils.mkdir_p(tmp_dir)

        report_file = file_name(report)
        tmp_file_path = File.join(tmp_dir, report_file)

        write_compressed_file(report, tmp_file_path)

        File.join(@reports_path, report_file).tap do |report_file_path|
          FileUtils.mv(tmp_file_path, report_file_path)
        end
      end

      def write_compressed_file(report, path)
        io_r, io_w = IO.pipe
        err_r, err_w = IO.pipe
        pid = nil
        status = nil
        File.open(path, 'wb') do |file|
          extras = {
            in: io_r,
            out: file,
            err: err_w
          }
          pid = Process.spawn(*COMPRESS_CMD, **extras)
          io_r.close
          err_w.close

          report.run(io_w)
          io_w.close

          _, status = Process.wait2(pid)
        end

        errors = err_r.read&.strip
        err_r.close
        raise StandardError, "exit #{status.exitstatus}: #{errors}" if !status&.success? && errors.present?
      ensure
        [io_r, io_w, err_r, err_w].each(&:close)
        # Make sure we don't leave any running processes behind.
        Gitlab::ProcessManagement.signal(pid, :KILL) if pid
      end

      def log_labels(**extra_labels)
        {
          pid: $$,
          worker_id: @worker_id,
          perf_report_worker_uuid: @worker_uuid
        }.merge(extra_labels)
      end

      def file_name(report)
        timestamp = Time.current.strftime('%Y-%m-%d.%H:%M:%S:%L')

        report_id = [@worker_id, @worker_uuid].join(".")

        [report.name, timestamp, report_id, 'gz'].compact_blank.join('.')
      end

      def file_size(file_path)
        File.size(file_path.to_s)
      rescue Errno::ENOENT
        0
      end

      def init_prometheus_metrics
        default_labels = { pid: @worker_id }

        @report_duration_counter = Gitlab::Metrics.counter(
          :gitlab_diag_report_duration_seconds_total,
          'Total time elapsed for running diagnostic report',
          default_labels
        )
      end
    end
  end
end
