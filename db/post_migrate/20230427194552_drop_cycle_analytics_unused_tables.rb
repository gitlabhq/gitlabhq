# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropCycleAnalyticsUnusedTables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    drop_table :analytics_cycle_analytics_project_stages
    drop_table :analytics_cycle_analytics_project_value_streams
  end

  def down
    create_analytics_cycle_analytics_project_value_streams_table
    create_analytics_cycle_analytics_project_stages_table
  end

  def create_analytics_cycle_analytics_project_value_streams_table
    index_name = 'index_analytics_ca_project_value_streams_on_project_id_and_name'

    # rubocop:disable Migration/SchemaAdditionMethodsNoPost
    # rubocop:disable Migration/AddLimitToTextColumns
    create_table :analytics_cycle_analytics_project_value_streams do |t|
      t.timestamps_with_timezone
      t.references(:project,
        null: false,
        index: false,
        foreign_key: { to_table: :projects, on_delete: :cascade }
      )
      t.text :name, null: false
      t.index [:project_id, :name], unique: true, name: index_name
    end
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost
    # rubocop:enable Migration/AddLimitToTextColumns

    add_text_limit :analytics_cycle_analytics_project_value_streams, :name, 100
  end

  def create_analytics_cycle_analytics_project_stages_table
    index_prefix = 'index_analytics_ca_project_stages_'

    # rubocop:disable Migration/SchemaAdditionMethodsNoPost
    create_table :analytics_cycle_analytics_project_stages do |t|
      t.timestamps_with_timezone
      t.integer :relative_position
      t.integer :start_event_identifier, null: false
      t.integer :end_event_identifier, null: false
      t.references(:project, null: false,
        foreign_key: { to_table: :projects, on_delete: :cascade },
        index: { name: "#{index_prefix}on_project_id" }
      )
      t.references(:start_event_label,
        foreign_key: { to_table: :labels, on_delete: :cascade },
        index: { name: "#{index_prefix}on_start_event_label_id" }
      )
      t.references(:end_event_label,
        foreign_key: { to_table: :labels, on_delete: :cascade },
        index: { name: "#{index_prefix}on_end_event_label_id" }
      )
      t.boolean :hidden, default: false, null: false
      t.boolean :custom, default: true, null: false
      t.string :name, null: false, limit: 255 # rubocop: disable Migration/PreventStrings
      t.references(:project_value_stream, null: false,
        foreign_key: { to_table: :analytics_cycle_analytics_project_value_streams, on_delete: :cascade },
        index: { name: "#{index_prefix}on_value_stream_id" }
      )
      t.references(:stage_event_hash,
        foreign_key: { to_table: :analytics_cycle_analytics_stage_event_hashes, on_delete: :cascade },
        index: { name: 'index_project_stages_on_stage_event_hash_id' }
      )
    end
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost

    add_check_constraint :analytics_cycle_analytics_project_stages, 'stage_event_hash_id IS NOT NULL',
      'check_8f6019de1e'

    add_index :analytics_cycle_analytics_project_stages, [:project_id, :name], unique: true,
      name: "#{index_prefix}on_project_id_and_name"
    add_index :analytics_cycle_analytics_project_stages, [:relative_position],
      name: "#{index_prefix}on_relative_position"
  end
end
