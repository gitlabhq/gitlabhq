# frozen_string_literal: true

module Gitlab
  module Memory
    class UploadAndCleanupReports
      DEFAULT_SLEEP_TIME_SECONDS = 900 # 15 minutes

      def initialize(
        sleep_time_seconds: ENV['GITLAB_DIAGNOSTIC_REPORTS_UPLOADER_SLEEP_S']&.to_i || DEFAULT_SLEEP_TIME_SECONDS,
        reports_path: ENV["GITLAB_DIAGNOSTIC_REPORTS_PATH"])

        @sleep_time_seconds = sleep_time_seconds
        @reports_path = reports_path

        unless @reports_path.present?
          log_error_reports_path_missing
          return
        end

        @uploader = ReportsUploader.new

        @alive = true
      end

      attr_reader :sleep_time_seconds, :reports_path, :uploader, :alive

      def call
        log_started

        while alive
          sleep(sleep_time_seconds)

          next unless Feature.enabled?(:gitlab_diagnostic_reports_uploader, type: :ops)

          files_to_process.each { |path| upload_and_cleanup!(path) }
        end
      end

      private

      def upload_and_cleanup!(path)
        cleanup!(path) if uploader.upload(path)
      rescue StandardError => error
        log_exception(error)
      end

      def cleanup!(path)
        File.unlink(path) if File.exist?(path)
      rescue Errno::ENOENT
        # Path does not exist: Ignore. We already check `File.exist?`. Rescue to be extra safe.
      end

      def files_to_process
        Dir.entries(reports_path)
          .map { |path| File.join(reports_path, path) }
          .select { |path| File.file?(path) }
      end

      def log_error_reports_path_missing
        Gitlab::AppLogger.error(log_labels.merge(perf_report_status: "path is not configured"))
      end

      def log_started
        Gitlab::AppLogger.info(log_labels.merge(perf_report_status: "started"))
      end

      def log_exception(error)
        Gitlab::ErrorTracking.log_exception(error, log_labels)
      end

      def log_labels
        {
          message: "Diagnostic reports",
          class: self.class.name,
          pid: $$,
          worker_id: worker_id
        }
      end

      def worker_id
        ::Prometheus::PidProvider.worker_id
      end
    end
  end
end
