# frozen_string_literal: true

module Gitlab
  module Memory
    class UploadAndCleanupReports
      DEFAULT_SLEEP_TIME_SECONDS = 900 # 15 minutes

      def initialize(
        uploader:,
        reports_path:,
        logger:,
        sleep_time_seconds: ENV['GITLAB_DIAGNOSTIC_REPORTS_UPLOADER_SLEEP_S']&.to_i || DEFAULT_SLEEP_TIME_SECONDS)

        @uploader = uploader
        @reports_path = reports_path
        @sleep_time_seconds = sleep_time_seconds
        @alive = true
        @logger = logger
      end

      attr_reader :uploader, :reports_path, :sleep_time_seconds, :logger

      def call
        log_started

        loop do
          sleep(sleep_time_seconds)

          files_to_process.each { |path| upload_and_cleanup!(path) }
        end
      end

      private

      def upload_and_cleanup!(path)
        uploader.upload(path)
      rescue StandardError, Errno::ENOENT => error
        log_exception(error)
      ensure
        cleanup!(path)
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

      def log_started
        logger.info(log_labels.merge(perf_report_status: "started"))
      end

      def log_exception(error)
        logger.error(log_labels.merge(perf_report_status: "error", error: error.message))
      end

      def log_labels
        {
          message: "Diagnostic reports",
          class: self.class.name,
          pid: $$
        }
      end
    end
  end
end
