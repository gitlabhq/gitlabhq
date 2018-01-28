module Gitlab
  module Checks
    class CommitCheck
      attr_reader :project, :user, :newrev, :oldrev

      def initialize(project, user, newrev, oldrev)
        @project = project
        @user = user
        @newrev = user
        @oldrev = user
      end

      def validate(commit, validations)
        return if validations.empty?

        commit.raw_deltas.each do |diff|
          validations.each do |validation|
            if error = validation.call(diff)
              raise ::Gitlab::GitAccess::UnauthorizedError, error
            end
          end
        end

        nil
      end

      def validations
        validate_lfs_file_locks? ? [lfs_file_locks_validation] : []
      end

      private

      def validate_lfs_file_locks?
        project.lfs_enabled? && project.lfs_file_locks.any? && newrev && oldrev
      end

      def lfs_file_locks_validation
        lambda do |diff|
          path = diff.new_path || diff.old_path

          lfs_lock = project.lfs_file_locks.find_by(path: path)

          if lfs_lock && lfs_lock.user != user
            return "The path '#{lfs_lock.path}' is locked in Git LFS by #{lfs_lock.user.name}"
          end
        end
      end
    end
  end
end
