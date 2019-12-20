# frozen_string_literal: true

module Gitlab
  module HookData
    class MergeRequestBuilder < BaseBuilder
      def self.safe_hook_attributes
        %i[
          assignee_id
          author_id
          created_at
          description
          head_pipeline_id
          id
          iid
          last_edited_at
          last_edited_by_id
          merge_commit_sha
          merge_error
          merge_params
          merge_status
          merge_user_id
          merge_when_pipeline_succeeds
          milestone_id
          source_branch
          source_project_id
          state_id
          target_branch
          target_project_id
          time_estimate
          title
          updated_at
          updated_by_id
        ].freeze
      end

      SAFE_HOOK_RELATIONS = %i[
        assignees
        labels
        total_time_spent
      ].freeze

      alias_method :merge_request, :object

      def build
        attrs = {
          description: absolute_image_urls(merge_request.description),
          url: Gitlab::UrlBuilder.build(merge_request),
          source: merge_request.source_project.try(:hook_attrs),
          target: merge_request.target_project.hook_attrs,
          last_commit: merge_request.diff_head_commit&.hook_attrs,
          work_in_progress: merge_request.work_in_progress?,
          total_time_spent: merge_request.total_time_spent,
          human_total_time_spent: merge_request.human_total_time_spent,
          human_time_estimate: merge_request.human_time_estimate,
          assignee_ids: merge_request.assignee_ids,
          assignee_id: merge_request.assignee_ids.first, # This key is deprecated
          state: merge_request.state # This key is deprecated
        }

        merge_request.attributes.with_indifferent_access.slice(*self.class.safe_hook_attributes)
          .merge!(attrs)
      end
    end
  end
end
