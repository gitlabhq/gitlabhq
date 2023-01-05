# frozen_string_literal: true

module Issues
  module LookAheadPreloads
    extend ActiveSupport::Concern

    prepended do
      include ::LooksAhead
    end

    private

    def unconditional_includes
      [
        {
          project: [:project_feature, :group]
        },
        :author
      ]
    end

    def preloads
      preload_hash = {
        alert_management_alert: [:alert_management_alert],
        assignees: [:assignees],
        participants: Issue.participant_includes,
        timelogs: [:timelogs],
        customer_relations_contacts: { customer_relations_contacts: [:group] },
        escalation_status: [:incident_management_issuable_escalation_status]
      }
      preload_hash[:type] = :work_item_type if Feature.enabled?(:issue_type_uses_work_item_types_table)

      preload_hash
    end
  end
end

Issues::LookAheadPreloads.prepend_mod
