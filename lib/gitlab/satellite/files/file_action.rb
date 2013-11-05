module Gitlab
  module Satellite
    class FileAction < Action
      attr_accessor :file_path, :ref

      def initialize(user, project, ref, file_path)
        super user, project, git_timeout: 10.seconds
        @file_path = file_path
        @ref = ref
      end

      protected

      def can_edit?(last_commit)
        current_last_commit = Gitlab::Git::Commit.last_for_path(@project.repository, ref, file_path).sha
        last_commit == current_last_commit
      end
    end
  end
end
