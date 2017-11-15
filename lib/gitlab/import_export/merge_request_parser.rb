module Gitlab
  module ImportExport
    class MergeRequestParser
      FORKED_PROJECT_ID = nil

      def initialize(project, diff_head_sha, merge_request, relation_hash)
        @project = project
        @diff_head_sha = diff_head_sha
        @merge_request = merge_request
        @relation_hash = relation_hash
      end

      def parse!
        if fork_merge_request? && @diff_head_sha
          @merge_request.source_project_id = @relation_hash['project_id']

          fetch_ref unless branch_exists?(@merge_request.source_branch)
          create_target_branch unless branch_exists?(@merge_request.target_branch)
        end

        @merge_request
      end

      def create_target_branch
        @project.repository.create_branch(@merge_request.target_branch, @merge_request.target_branch_sha)
      end

      def fetch_ref
        @project.repository.fetch_ref(@project.repository, source_ref: @diff_head_sha, target_ref: @merge_request.source_branch)
      end

      def branch_exists?(branch_name)
        @project.repository.raw.branch_exists?(branch_name)
      end

      def fork_merge_request?
        @relation_hash['source_project_id'] == FORKED_PROJECT_ID
      end
    end
  end
end
