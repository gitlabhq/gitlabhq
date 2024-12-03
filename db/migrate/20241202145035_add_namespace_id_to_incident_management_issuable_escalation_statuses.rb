# frozen_string_literal: true

class AddNamespaceIdToIncidentManagementIssuableEscalationStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :incident_management_issuable_escalation_statuses, :namespace_id, :bigint
  end
end
