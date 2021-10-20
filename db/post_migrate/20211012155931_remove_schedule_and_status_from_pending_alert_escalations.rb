# frozen_string_literal: true

class RemoveScheduleAndStatusFromPendingAlertEscalations < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  ESCALATIONS_TABLE = :incident_management_pending_alert_escalations
  SCHEDULES_TABLE = :incident_management_oncall_schedules
  INDEX_NAME = 'index_incident_management_pending_alert_escalations_on_schedule'
  CONSTRAINT_NAME = 'fk_rails_fcbfd9338b'

  def up
    with_lock_retries do
      remove_column ESCALATIONS_TABLE, :schedule_id
      remove_column ESCALATIONS_TABLE, :status
    end
  end

  def down
    with_lock_retries do
      add_column ESCALATIONS_TABLE, :schedule_id, :bigint unless column_exists?(ESCALATIONS_TABLE, :schedule_id)
      add_column ESCALATIONS_TABLE, :status, :smallint unless column_exists?(ESCALATIONS_TABLE, :status)
    end

    add_concurrent_partitioned_index ESCALATIONS_TABLE, :schedule_id, name: INDEX_NAME
    add_concurrent_partitioned_foreign_key ESCALATIONS_TABLE, SCHEDULES_TABLE, column: :schedule_id, name: CONSTRAINT_NAME
  end
end
