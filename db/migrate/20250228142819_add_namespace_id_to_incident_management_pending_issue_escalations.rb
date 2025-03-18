# frozen_string_literal: true

class AddNamespaceIdToIncidentManagementPendingIssueEscalations < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :incident_management_pending_issue_escalations, :namespace_id, :bigint
  end
end
