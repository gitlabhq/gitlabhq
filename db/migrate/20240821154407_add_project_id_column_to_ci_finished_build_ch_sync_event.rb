# frozen_string_literal: true

class AddProjectIdColumnToCiFinishedBuildChSyncEvent < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    # Normally, we'd make this a nullable column, and over the course of multiple milestones, make it a
    # non-nullable column with a constraint.
    # We can save time knowing that the records in this table have a maximum lifetime of 30 days
    #   (less in .com since the daily partition gets dropped after being processed by the worker).
    # We'll start by adding -1 to all project_ids, knowing that this value is not used yet.
    # Once all the rows have valid values, we can drop all the rows having a -1 project_id.
    add_column :p_ci_finished_build_ch_sync_events, :project_id, :bigint, default: -1, null: false
  end
end
