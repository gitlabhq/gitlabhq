# frozen_string_literal: true

class CreateProjectValueStreams < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_analytics_ca_project_value_streams_on_project_id_and_name'

  def up
    create_table_with_constraints :analytics_cycle_analytics_project_value_streams do |t|
      t.timestamps_with_timezone
      t.references(:project,
                   null: false,
                   index: false,
                   foreign_key: { to_table: :projects, on_delete: :cascade }
                  )
      t.text :name, null: false
      t.index [:project_id, :name], unique: true, name: INDEX_NAME
      t.text_limit :name, 100
    end
  end

  def down
    with_lock_retries do
      drop_table :analytics_cycle_analytics_project_value_streams
    end
  end
end
