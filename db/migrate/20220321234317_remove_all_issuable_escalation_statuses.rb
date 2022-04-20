# frozen_string_literal: true

class RemoveAllIssuableEscalationStatuses < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 5_000

  disable_ddl_transaction!

  # Removes records from previous backfill. Records for
  # existing incidents will be created entirely as-needed.
  #
  # See db/post_migrate/20211214012507_backfill_incident_issue_escalation_statuses.rb,
  # & IncidentManagement::IssuableEscalationStatuses::[BuildService,PrepareUpdateService]
  def up
    each_batch_range('incident_management_issuable_escalation_statuses', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM incident_management_issuable_escalation_statuses
        WHERE id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no-op
    #
    # Potential rollback/re-run should not have impact, as these
    # records are not required to be present in the application.
    # The corresponding feature flag is also disabled,
    # preventing any user-facing access to the records.
  end
end
