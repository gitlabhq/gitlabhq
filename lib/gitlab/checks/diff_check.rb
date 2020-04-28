# frozen_string_literal: true

module Gitlab
  module Checks
    class DiffCheck < BaseChecker
      include Gitlab::Utils::StrongMemoize

      LOG_MESSAGES = {
        validate_file_paths: "Validating diffs' file paths...",
        diff_content_check: "Validating diff contents..."
      }.freeze

      def validate!
        return if deletion?
        return unless should_run_diff_validations?
        return if commits.empty?

        file_paths = []

        process_commits do |commit|
          validate_once(commit) do
            commit.raw_deltas.each do |diff|
              file_paths.concat([diff.new_path, diff.old_path].compact)

              validate_diff(diff)
            end
          end
        end

        validate_file_paths(file_paths)
      end

      private

      def validate_lfs_file_locks?
        strong_memoize(:validate_lfs_file_locks) do
          project.lfs_enabled? && project.any_lfs_file_locks?
        end
      end

      def should_run_diff_validations?
        validations_for_diff.present? || path_validations.present?
      end

      def validate_diff(diff)
        validations_for_diff.each do |validation|
          if error = validation.call(diff)
            raise ::Gitlab::GitAccess::ForbiddenError, error
          end
        end
      end

      # Method overwritten in EE to inject custom validations
      def validations_for_diff
        []
      end

      def path_validations
        validate_lfs_file_locks? ? [lfs_file_locks_validation] : []
      end

      def process_commits
        logger.log_timed(LOG_MESSAGES[:diff_content_check]) do
          # n+1: https://gitlab.com/gitlab-org/gitlab/issues/3593
          ::Gitlab::GitalyClient.allow_n_plus_1_calls do
            commits.each do |commit|
              logger.check_timeout_reached

              yield(commit)
            end
          end
        end
      end

      def validate_file_paths(file_paths)
        logger.log_timed(LOG_MESSAGES[__method__]) do
          path_validations.each do |validation|
            if error = validation.call(file_paths)
              raise ::Gitlab::GitAccess::ForbiddenError, error
            end
          end
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def lfs_file_locks_validation
        lambda do |paths|
          lfs_lock = project.lfs_file_locks.where(path: paths).where.not(user_id: user_access.user.id).take

          if lfs_lock
            return "The path '#{lfs_lock.path}' is locked in Git LFS by #{lfs_lock.user.name}"
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

Gitlab::Checks::DiffCheck.prepend_if_ee('EE::Gitlab::Checks::DiffCheck')
