# frozen_string_literal: true

module Gitlab
  module HookData
    class IssuableBuilder < BaseBuilder
      CHANGES_KEYS = %i[previous current].freeze

      alias_method :issuable, :object

      def build(user: nil, changes: {})
        hook_data = {
          object_kind: object_kind,
          event_type: event_type,
          user: user.hook_attrs,
          project: issuable.project.hook_attrs,
          object_attributes: issuable.hook_attrs,
          labels: issuable.labels.map(&:hook_attrs),
          changes: final_changes(changes.slice(*safe_keys)),
          # DEPRECATED
          repository: issuable.project.hook_attrs.slice(:name, :url, :description, :homepage)
        }

        hook_data[:assignees] = issuable.assignees.map(&:hook_attrs) if issuable.assignees.any?

        hook_data
      end

      def safe_keys
        issuable_builder.safe_hook_attributes + issuable_builder::SAFE_HOOK_RELATIONS
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
        changes_hash.reduce({}) do |hash, (key, changes_array)|
          hash[key] = Hash[CHANGES_KEYS.zip(changes_array)]
          hash
        end
      end
    end
  end
end
