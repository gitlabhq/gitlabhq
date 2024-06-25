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
          hook_data[:reviewers] = issuable.reviewers.map(&:hook_attrs)
        end

        hook_data
      end

      def safe_keys
        issuable_builder.safe_hook_attributes + issuable_builder.safe_hook_relations
      end

      private

      def object_kind
        issuable.class.name.underscore
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
    end
  end
end
