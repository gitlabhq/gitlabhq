# frozen_string_literal: true

module Gitlab
  module Checks
    class GlobalFileSizeCheck < BaseBulkChecker
      LOG_MESSAGE = 'Checking for blobs over the file size limit'

      def validate!
        return unless Feature.enabled?(:global_file_size_check, project)

        Gitlab::AppJsonLogger.info(LOG_MESSAGE)
        logger.log_timed(LOG_MESSAGE) do
          oversized_blobs = Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs.new(
            project: project,
            changes: changes,
            file_size_limit_megabytes: file_size_limit
          ).find

          if oversized_blobs.present?

            blob_details = {}
            blob_id_size_msg = ""
            oversized_blobs.each do |blob|
              blob_details[blob.id] = { "size" => blob.size }

              # blob size is in byte, divide it by "/ 1024.0 / 1024.0" to get MiB
              blob_id_size_msg += "- #{blob.id} (#{(blob.size / 1024.0 / 1024.0).round(2)} MiB) \n"
            end

            oversize_err_msg = <<~OVERSIZE_ERR_MSG
              You are attempting to check in one or more blobs which exceed the #{file_size_limit}MiB limit:

              #{blob_id_size_msg}
              To resolve this error, you must either reduce the size of the above blobs, or utilize LFS.
              You may use "git ls-tree -r HEAD | grep $BLOB_ID" to see the file path.
              Please refer to #{Rails.application.routes.url_helpers.help_page_url('user/free_push_limit')} and
              #{Rails.application.routes.url_helpers.help_page_url('administration/settings/account_and_limit_settings')}
              for further information.
            OVERSIZE_ERR_MSG

            Gitlab::AppJsonLogger.info(
              message: 'Found blob over global limit',
              blob_sizes: oversized_blobs.map(&:size),
              blob_details: blob_details
            )

            raise ::Gitlab::GitAccess::ForbiddenError, oversize_err_msg if enforce_global_file_size_limit?
          end
        end

        true
      end

      private

      def file_size_limit
        project.actual_limits.file_size_limit_mb
      end

      def enforce_global_file_size_limit?
        Feature.enabled?(:enforce_global_file_size_limit, project)
      end
    end
  end
end
