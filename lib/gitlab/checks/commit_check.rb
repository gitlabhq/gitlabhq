module Gitlab
  module Checks
    class CommitCheck
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :user, :newrev, :oldrev

      def initialize(project, user, newrev, oldrev)
        @project = project
        @user = user
        @newrev = user
        @oldrev = user
        @file_paths = []
      end

      def validate(commit, validations)
        return if validations.empty? && path_validations.empty?

        commit.raw_deltas.each do |diff|
          @file_paths << (diff.new_path || diff.old_path)

          validations.each do |validation|
            if error = validation.call(diff)
              raise ::Gitlab::GitAccess::UnauthorizedError, error
            end
          end
        end
      end

      def validate_file_paths
        path_validations.each do |validation|
          if error = validation.call(@file_paths)
            raise ::Gitlab::GitAccess::UnauthorizedError, error
          end
        end
      end

      def validate_lfs_file_locks?
        strong_memoize(:validate_lfs_file_locks) do
          project.lfs_enabled? && project.lfs_file_locks.any? && newrev && oldrev
        end
      end

      private

      def lfs_file_locks_validation
        lambda do |paths|
          lfs_lock = project.lfs_file_locks.where(path: paths).where.not(user_id: user.id).first

          if lfs_lock
            return "The path '#{lfs_lock.path}' is locked in Git LFS by #{lfs_lock.user.name}"
          end
        end
      end

      def path_validations
        validate_lfs_file_locks? ? [lfs_file_locks_validation] : []
      end
    end
  end
end
