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

      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/1295
      def fetch_ref
        target_ref = Gitlab::Git::BRANCH_REF_PREFIX + @merge_request.source_branch

        unless @project.repository.fetch_source_branch!(@project.repository, @diff_head_sha, target_ref)
          Rails.logger.warn("Import/Export warning: Failed to create #{target_ref} for MR: #{@merge_request.iid}")
        end
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
