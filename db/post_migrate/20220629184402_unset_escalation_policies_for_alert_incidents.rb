# frozen_string_literal: true

class UnsetEscalationPoliciesForAlertIncidents < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class EscalationStatus < MigrationRecord
    include EachBatch

    self.table_name = 'incident_management_issuable_escalation_statuses'

    scope :having_alert_policy, -> do
      joins(
        'INNER JOIN alert_management_alerts ' \
        'ON alert_management_alerts.issue_id ' \
        '= incident_management_issuable_escalation_statuses.issue_id'
      )
    end
  end

  def up
    EscalationStatus.each_batch do |escalation_statuses|
      escalation_statuses
        .where.not(policy_id: nil)
        .having_alert_policy
        .update_all(policy_id: nil, escalations_started_at: nil)
    end
  end

  def down
    # no-op
    #
    # We cannot retrieve the exact nullified values. We could
    # approximately guess what the values are via the alert's
    # escalation policy. However, that may not be accurate
    # in all cases, as an alert's escalation policy is implictly
    # inferred from the project rather than explicit, like an incident.
    # So we won't backfill potentially incorrect data.
    #
    # This data is functionally safe to delete, as the relevant
    # fields are read-only, and exclusively informational.
    #
    # Re-running the migration will have no effect.
  end
end
