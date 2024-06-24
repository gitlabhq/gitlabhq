# frozen_string_literal: true

module Gitlab
  module HookData
    # Used for legacy issues, Service Desk issues and all work item types
    # See https://gitlab.com/groups/gitlab-org/-/epics/10150
    class IssueBuilder < BaseBuilder
      def self.safe_hook_relations
        %i[
          assignees
          labels
          total_time_spent
          time_change
          severity
          escalation_status
          customer_relations_contacts
        ].freeze
      end

      def self.safe_hook_attributes
        %i[
          assignee_id
          author_id
          closed_at
          confidential
          created_at
          description
          discussion_locked
          due_date
          id
          iid
          last_edited_at
          last_edited_by_id
          milestone_id
          moved_to_id
          duplicated_to_id
          project_id
          relative_position
          state_id
          time_estimate
          title
          updated_at
          updated_by_id
        ].freeze
      end

      alias_method :issue, :object

      def build
        attrs = {
          type: issue.work_item_type.name,
          description: absolute_image_urls(issue.description),
          url: Gitlab::UrlBuilder.build(issue),
          total_time_spent: issue.total_time_spent,
          time_change: issue.time_change,
          human_total_time_spent: issue.human_total_time_spent,
          human_time_change: issue.human_time_change,
          human_time_estimate: issue.human_time_estimate,
          assignee_ids: issue.assignee_ids,
          assignee_id: issue.assignee_ids.first, # This key is deprecated
          labels: issue.labels_hook_attrs,
          state: issue.state,
          severity: issue.severity,
          customer_relations_contacts: issue.customer_relations_contacts.map(&:hook_attrs)
        }

        if issue.supports_escalation? && issue.escalation_status
          attrs[:escalation_status] = issue.escalation_status.status_name
        end

        issue.attributes.with_indifferent_access.slice(*self.class.safe_hook_attributes)
          .merge!(attrs)
      end
    end
  end
end

Gitlab::HookData::IssueBuilder.prepend_mod_with('Gitlab::HookData::IssueBuilder')
