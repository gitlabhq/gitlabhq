module Gitlab
  module HookData
    class IssuableBuilder
      attr_accessor :issuable

      def initialize(issuable)
        @issuable = issuable
      end

      def build(user: nil, changes: {})
        hook_data = {
          object_kind: issuable.class.name.underscore,
          user: user.hook_attrs,
          project: issuable.project.hook_attrs,
          object_attributes: issuable.hook_attrs,
          labels: issuable.labels.map(&:hook_attrs),
          changes: changes.slice(*safe_keys),
          # DEPRECATED
          repository: issuable.project.hook_attrs.slice(:name, :url, :description, :homepage)
        }

        if issuable.is_a?(Issue)
          hook_data[:assignees] = issuable.assignees.map(&:hook_attrs) if issuable.assignees.any?
        else
          hook_data[:assignee] = issuable.assignee.hook_attrs if issuable.assignee
        end

        hook_data
      end

      def safe_keys
        issuable.class.safe_hook_attributes + issuable.class.safe_hook_relations
      end
    end
  end
end
