# frozen_string_literal: true

class UpdateAiTroubleshootJobEventsProjectFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.0'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ai_troubleshoot_job_events, column: :project_id, reverse_lock_order: true)
    end

    add_concurrent_partitioned_foreign_key :ai_troubleshoot_job_events, :projects, column: :project_id,
      on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:ai_troubleshoot_job_events, column: :project_id, reverse_lock_order: true)
    end

    add_concurrent_partitioned_foreign_key :ai_troubleshoot_job_events, :projects, column: :project_id, on_delete: nil,
      reverse_lock_order: true
  end
end
