# frozen_string_literal: true

module Gitlab
  module HookData
    class MergeRequestBuilder < BaseBuilder
      def self.safe_hook_attributes
        %i[
          assignee_id
          author_id
          blocking_discussions_resolved
          created_at
          description
          draft
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
          reviewer_ids
          source_branch
          source_project_id
          state_id
          target_branch
          target_project_id
          time_estimate
          title
          updated_at
          updated_by_id
          prepared_at
        ].freeze
      end

      def self.safe_hook_relations
        %i[
          assignees
          labels
          reviewers
          total_time_spent
          time_change
        ].freeze
      end

      alias_method :merge_request, :object
      def build
        attrs = {
          assignee_id: merge_request.assignee_ids.first, # This key is deprecated
          assignee_ids: merge_request.assignee_ids,
          blocking_discussions_resolved: merge_request.mergeable_discussions_state?,
          description: absolute_image_urls(merge_request.description),
          detailed_merge_status: detailed_merge_status,
          draft: merge_request.draft?,
          first_contribution: merge_request.first_contribution?,
          human_time_change: merge_request.human_time_change,
          human_time_estimate: merge_request.human_time_estimate,
          human_total_time_spent: merge_request.human_total_time_spent,
          labels: merge_request.labels_hook_attrs,
          last_commit: merge_request.diff_head_commit&.hook_attrs,
          reviewer_ids: merge_request.reviewer_ids,
          source: merge_request.source_project.try(:hook_attrs),
          state: merge_request.state,
          target: merge_request.target_project.hook_attrs,
          target_branch: merge_request.target_branch,
          time_change: merge_request.time_change,
          total_time_spent: merge_request.total_time_spent,
          url: Gitlab::UrlBuilder.build(merge_request),
          work_in_progress: merge_request.draft?
        }

        merge_request.attributes.with_indifferent_access.slice(*self.class.safe_hook_attributes)
          .merge!(attrs)
      end

      private

      def detailed_merge_status
        ::MergeRequests::Mergeability::DetailedMergeStatusService.new(merge_request: merge_request).execute.to_s
      end
    end
  end
end

Gitlab::HookData::MergeRequestBuilder.prepend_mod_with('Gitlab::HookData::MergeRequestBuilder')
