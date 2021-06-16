# frozen_string_literal: true

module Gitlab
  module Checks
    class DiffCheck < BaseSingleChecker
      include Gitlab::Utils::StrongMemoize

      LOG_MESSAGES = {
        validate_file_paths: "Validating diffs' file paths..."
      }.freeze

      def validate!
        return if deletion?
        return unless should_run_validations?
        return if commits.empty?

        paths = project.repository.find_changed_paths(commits.map(&:sha))
        paths.each do |path|
          validate_path(path)
        end

        validate_file_paths(paths.map(&:path).uniq)
      end

      private

      def validate_lfs_file_locks?
        strong_memoize(:validate_lfs_file_locks) do
          project.lfs_enabled? && project.any_lfs_file_locks?
        end
      end

      def should_run_validations?
        validations_for_path.present? || file_paths_validations.present?
      end

      def validate_path(path)
        validations_for_path.each do |validation|
          if error = validation.call(path)
            raise ::Gitlab::GitAccess::ForbiddenError, error
          end
        end
      end

      # Method overwritten in EE to inject custom validations
      def validations_for_path
        []
      end

      def file_paths_validations
        validate_lfs_file_locks? ? [lfs_file_locks_validation] : []
      end

      def validate_file_paths(file_paths)
        logger.log_timed(LOG_MESSAGES[__method__]) do
          file_paths_validations.each do |validation|
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

Gitlab::Checks::DiffCheck.prepend_mod_with('Gitlab::Checks::DiffCheck')
