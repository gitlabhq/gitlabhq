# frozen_string_literal: true

class ChangeAiTroubleshootJobEventsProjectFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.0'

  def up
    remove_foreign_key :ai_troubleshoot_job_events, column: :project_id
    add_concurrent_partitioned_foreign_key :ai_troubleshoot_job_events, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key :ai_troubleshoot_job_events, column: :project_id
    add_concurrent_partitioned_foreign_key :ai_troubleshoot_job_events, :projects, column: :project_id, on_delete: nil
  end
end
