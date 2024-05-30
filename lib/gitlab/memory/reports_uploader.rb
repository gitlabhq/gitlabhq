# frozen_string_literal: true

require_relative '../metrics/system'

module Gitlab
  module Memory
    class ReportsUploader
      def initialize(gcs_key:, gcs_project:, gcs_bucket:, logger:)
        @gcs_bucket = gcs_bucket
        @fog = Fog::Storage::Google.new(google_project: gcs_project, google_json_key_location: gcs_key)
        @logger = logger
      end

      def upload(path)
        log_upload_requested(path)
        start_monotonic_time = ::Gitlab::Metrics::System.monotonic_time

        File.open(path.to_s) { |file| fog.put_object(gcs_bucket, File.basename(path), file) }

        duration_s = ::Gitlab::Metrics::System.monotonic_time - start_monotonic_time
        log_upload_success(path, duration_s)
      rescue StandardError, Errno::ENOENT => error
        log_exception(error)
      end

      private

      attr_reader :gcs_bucket, :fog, :logger

      def log_upload_requested(path)
        logger.info(log_labels.merge(perf_report_status: 'upload requested', perf_report_path: path))
      end

      def log_upload_success(path, duration_s)
        logger.info(log_labels.merge(perf_report_status: 'upload success', perf_report_path: path,
          duration_s: duration_s))
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
