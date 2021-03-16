# frozen_string_literal: true

module Gitlab
  module Checks
    class LfsCheck < BaseChecker
      LOG_MESSAGE = 'Scanning repository for blobs stored in LFS and verifying their files have been uploaded to GitLab...'
      ERROR_MESSAGE = 'LFS objects are missing. Ensure LFS is properly set up or try a manual "git lfs push --all".'

      def validate!
        # This feature flag is used for disabling integrify check on some envs
        # because these costy calculations may cause performance issues
        return unless Feature.enabled?(:lfs_check, default_enabled: true)

        return unless project.lfs_enabled?
        return if skip_lfs_integrity_check
        return if deletion?

        logger.log_timed(LOG_MESSAGE) do
          lfs_check = Checks::LfsIntegrity.new(project, newrev, logger.time_left)

          if lfs_check.objects_missing?
            raise GitAccess::ForbiddenError, ERROR_MESSAGE
          end
        end
      end
    end
  end
end
