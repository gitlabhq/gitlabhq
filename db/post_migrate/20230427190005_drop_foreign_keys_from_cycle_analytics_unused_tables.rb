# frozen_string_literal: true

class DropForeignKeysFromCycleAnalyticsUnusedTables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :analytics_cycle_analytics_project_stages, column: :stage_event_hash_id
      remove_foreign_key :analytics_cycle_analytics_project_stages, column: :project_id
      remove_foreign_key :analytics_cycle_analytics_project_stages, column: :start_event_label_id
      remove_foreign_key :analytics_cycle_analytics_project_stages, column: :end_event_label_id
      remove_foreign_key :analytics_cycle_analytics_project_stages, column: :project_value_stream_id

      remove_foreign_key :analytics_cycle_analytics_project_value_streams, column: :project_id
    end
  end

  def down
    add_concurrent_foreign_key(:analytics_cycle_analytics_project_stages,
      :analytics_cycle_analytics_stage_event_hashes,
      name: "fk_c3339bdfc9",
      column: :stage_event_hash_id,
      target_column: :id,
      on_delete: :cascade
    )

    add_concurrent_foreign_key(:analytics_cycle_analytics_project_stages,
      :labels,
      name: "fk_rails_1722574860",
      column: :start_event_label_id,
      target_column: :id,
      on_delete: :cascade
    )

    add_concurrent_foreign_key(:analytics_cycle_analytics_project_stages,
      :projects,
      name: "fk_rails_3829e49b66",
      column: :project_id,
      target_column: :id,
      on_delete: :cascade
    )

    add_concurrent_foreign_key(:analytics_cycle_analytics_project_stages,
      :labels,
      name: "fk_rails_3ec9fd7912",
      column: :end_event_label_id,
      target_column: :id,
      on_delete: :cascade
    )

    add_concurrent_foreign_key(:analytics_cycle_analytics_project_stages,
      :analytics_cycle_analytics_project_value_streams,
      name: "fk_rails_796a7dbc9c",
      column: :project_value_stream_id,
      target_column: :id,
      on_delete: :cascade
    )

    add_concurrent_foreign_key(:analytics_cycle_analytics_project_value_streams,
      :projects,
      name: "fk_rails_669f4ba293",
      column: :project_id,
      target_column: :id,
      on_delete: :cascade
    )
  end
end
