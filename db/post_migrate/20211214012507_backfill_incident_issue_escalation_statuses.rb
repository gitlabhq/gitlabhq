# frozen_string_literal: true

class BackfillIncidentIssueEscalationStatuses < Gitlab::Database::Migration[1.0]
  # Removed in favor of creating records for existing incidents
  # as-needed. See db/migrate/20220321234317_remove_all_issuable_escalation_statuses.rb.
  def change
    # no-op
  end
end
