# frozen_string_literal: true

module Gitlab
  module Checks
    class GlobalFileSizeCheck < BaseBulkChecker
      include ActionView::Helpers::NumberHelper

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
            blob_id_size_msg = oversized_blobs.map do |blob|
              "- #{blob.id} (#{number_to_human_size(blob.size)})"
            end.join("\n")

            oversize_err_msg = <<~OVERSIZE_ERR_MSG
            You are attempting to check in one or more blobs which exceed the #{file_size_limit}MiB limit:

            #{blob_id_size_msg}
            To resolve this error, you must either reduce the size of the above blobs, or utilize LFS.
            You may use "git ls-tree -r HEAD | grep $BLOB_ID" to see the file path.
            Please refer to #{Rails.application.routes.url_helpers.help_page_url('user/free_push_limit.md')} and
            #{Rails.application.routes.url_helpers.help_page_url('administration/settings/account_and_limit_settings.md')}
            for further information.
            OVERSIZE_ERR_MSG

            Gitlab::AppJsonLogger.info(
              message: 'Found blob over global limit',
              blob_details: oversized_blobs.map { |blob| { "id" => blob.id, "size" => blob.size } }
            )

            raise ::Gitlab::GitAccess::ForbiddenError, oversize_err_msg
          end
        end

        true
      end

      private

      def file_size_limit
        project.actual_limits.file_size_limit_mb
      end
    end
  end
end
