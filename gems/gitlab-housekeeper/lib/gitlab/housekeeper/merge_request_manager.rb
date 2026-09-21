# frozen_string_literal: true

require 'gitlab/housekeeper/gitlab_client'

module Gitlab
  module Housekeeper
    class MergeRequestManager
      def initialize(git:, target_branch:, push_when_approved:, push_when_conflict:)
        @git = git
        @target_branch = target_branch
        @push_when_approved = push_when_approved
        @push_when_conflict = push_when_conflict
      end

      def setup(change, branch_name, keep)
        merge_request = existing_merge_request(branch_name) || create_or_update(change, branch_name, keep)
        change.mr_web_url = merge_request['web_url']
        change.has_conflicts = merge_request['has_conflicts'] || false
      end

      def create_or_update(change, branch_name, keep)
        change.non_housekeeper_changes = gitlab_client.non_housekeeper_changes(**project_scope(branch_name))

        if keep.should_push_code?(change, push_when_approved, push_when_conflict: push_when_conflict)
          git.push(branch_name, change.push_options)
        end

        gitlab_client.create_or_update_merge_request(change: change, **project_scope(branch_name))
      end

      def existing_merge_request(branch_name)
        gitlab_client.get_existing_merge_request(**project_scope(branch_name))
      end

      def closed_merge_request_exists?(branch_name)
        gitlab_client.closed_merge_request_exists?(**project_scope(branch_name))
      end

      private

      attr_reader :git, :target_branch, :push_when_approved, :push_when_conflict

      def gitlab_client
        @gitlab_client ||= GitlabClient.new
      end

      def project_scope(branch_name)
        {
          source_project_id: fork_project_id,
          source_branch: branch_name,
          target_branch: target_branch,
          target_project_id: target_project_id
        }
      end

      def fork_project_id
        ENV.fetch('HOUSEKEEPER_FORK_PROJECT_ID', target_project_id)
      end

      def target_project_id
        ENV.fetch('HOUSEKEEPER_TARGET_PROJECT_ID')
      end
    end
  end
end
