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
            Gitlab::AppJsonLogger.info(
              message: 'Found blob over global limit',
              blob_sizes: oversized_blobs.map(&:size)
            )

            if enforce_global_file_size_limit?
              raise ::Gitlab::GitAccess::ForbiddenError,
                "Changes include a file that is larger than the allowed size of #{file_size_limit} MiB. " \
                "Use Git LFS to manage this file.)"
            end
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
