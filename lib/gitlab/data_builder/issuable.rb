# frozen_string_literal: true

module Gitlab
  module DataBuilder
    class Issuable
      CHANGES_KEYS = %i[previous current].freeze

      attr_reader :issuable

      def initialize(issuable)
        @issuable = issuable
      end

      def build(user: nil, changes: {}, action: nil)
        hook_data = {
          object_kind: object_kind,
          event_type: event_type,
          user: user.hook_attrs,
          project: issuable.project&.hook_attrs,
          object_attributes: issuable_builder.new(issuable).build,
          labels: issuable.labels_hook_attrs,
          changes: final_changes(changes.slice(*safe_keys)),
          # DEPRECATED
          repository: issuable.project&.hook_attrs&.slice(:name, :url, :description, :homepage)
        }

        hook_data[:object_attributes][:action] = action if action
        hook_data[:assignees] = issuable.assignees.map(&:hook_attrs) if issuable.assignees.any?

        if issuable.allows_reviewers? && issuable.reviewers.any?
          # Check if there's a re-requested reviewer in the changes
          re_requested_reviewer_id = extract_re_requested_reviewer_id(changes)
          hook_data[:reviewers] = issuable.reviewers_hook_attrs(re_requested_reviewer_id: re_requested_reviewer_id)
        end

        hook_data
      end

      def safe_keys
        issuable_builder.safe_hook_attributes + issuable_builder.safe_hook_relations
      end

      private

      def object_kind
        # To prevent a breaking change, ensure we use `issue` for work items of type issue.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/517947
        if issuable.is_a?(WorkItem) && issuable.work_item_type.issue?
          "issue"
        else
          issuable.class.name.underscore
        end
      end

      def event_type
        if issuable.try(:confidential?)
          "confidential_#{object_kind}"
        else
          object_kind
        end
      end

      def issuable_builder
        case issuable
        when Issue
          Gitlab::HookData::IssueBuilder
        when MergeRequest
          Gitlab::HookData::MergeRequestBuilder
        end
      end

      def final_changes(changes_hash)
        changes_hash.transform_values { |changes_array| Hash[CHANGES_KEYS.zip(changes_array)] }
      end

      def extract_re_requested_reviewer_id(changes)
        # Look for a reviewer change where any reviewer has re_requested: true
        return unless changes[:reviewers].present?

        _old_reviewers, current_reviewers = changes[:reviewers]
        return unless current_reviewers.present?

        # Find the reviewer with re_requested: true in the current state
        re_requested_reviewer = current_reviewers.find { |reviewer| reviewer[:re_requested] == true }
        re_requested_reviewer&.dig(:id)
      end
    end
  end
end
