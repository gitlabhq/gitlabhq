# frozen_string_literal: true

class CreateAnalyticsCycleAnalyticsGroupValueStreams < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_analytics_ca_group_value_streams_on_group_id_and_name'

  disable_ddl_transaction!

  def up
    unless table_exists?(:analytics_cycle_analytics_group_value_streams)
      with_lock_retries do
        create_table :analytics_cycle_analytics_group_value_streams do |t|
          t.timestamps_with_timezone
          t.references(:group,
            null: false,
            index: false,
            foreign_key: { to_table: :namespaces, on_delete: :cascade }
          )
          t.text :name, null: false
          t.index [:group_id, :name], unique: true, name: INDEX_NAME
        end
      end
    end

    add_text_limit :analytics_cycle_analytics_group_value_streams, :name, 100
  end

  def down
    drop_table :analytics_cycle_analytics_group_value_streams
  end
end
