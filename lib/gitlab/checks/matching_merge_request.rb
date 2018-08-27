module Gitlab
  module Checks
    class MatchingMergeRequest
      def initialize(newrev, branch_name, project)
        @newrev = newrev
        @branch_name = branch_name
        @project = project
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def match?
        @project.merge_requests
          .with_state(:locked)
          .where(in_progress_merge_commit_sha: @newrev, target_branch: @branch_name)
          .exists?
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
