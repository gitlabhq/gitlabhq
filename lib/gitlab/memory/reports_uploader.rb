# frozen_string_literal: true

module Gitlab
  module Memory
    class ReportsUploader
      # This is no-op currently, it will only write logs.
      # The uploader implementation will be done in the next MR(s). For more details, check:
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97155#note_1099244930
      def upload(path)
        log_upload_requested(path)

        false # nothing is uploaded in the current implementation
      end

      private

      def log_upload_requested(path)
        Gitlab::AppLogger.info(log_labels.merge(perf_report_status: 'upload requested', perf_report_path: path))
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
