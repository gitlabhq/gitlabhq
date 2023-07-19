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
          Gitlab::Checks::FileSizeCheck::AllowExistingOversizedBlobs.new(
            project: project,
            changes: changes,
            file_size_limit_megabytes: MAX_FILE_SIZE_MB
          ).find

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/393535
          # - set limit per plan tier
          # - raise an error if large blobs are found
        end

        true
      end
    end
  end
end
