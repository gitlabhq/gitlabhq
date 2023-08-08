# frozen_string_literal: true

module Gitlab
  module Checks
    class GlobalFileSizeCheck < BaseBulkChecker
      MAX_FILE_SIZE_MB = 100
      LOG_MESSAGE = 'Checking for blobs over the file size limit'

      def validate!
        return unless Feature.enabled?(:global_file_size_check, project)

        Gitlab::AppJsonLogger.info(LOG_MESSAGE)
        logger.log_timed(LOG_MESSAGE) do
          oversized_blobs = Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs.new(
            project: project,
            changes: changes,
            file_size_limit_megabytes: MAX_FILE_SIZE_MB
          ).find

          if oversized_blobs.present?
            Gitlab::AppJsonLogger.info(
              message: 'Found blob over global limit',
              blob_sizes: oversized_blobs.map(&:size)
            )
          end

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/393535
          # - set limit per plan tier
          # - raise an error if large blobs are found
        end

        true
      end
    end
  end
end
