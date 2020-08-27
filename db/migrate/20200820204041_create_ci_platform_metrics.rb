# frozen_string_literal: true

class CreateCiPlatformMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_platform_metrics)
      create_table :ci_platform_metrics do |t|
        t.datetime_with_timezone :recorded_at, null: false
        t.text :platform_target, null: false
        t.integer :count, null: false
      end
    end

    add_text_limit :ci_platform_metrics, :platform_target, 255
    add_concurrent_index :ci_variables, :key
  end

  def down
    drop_table :ci_platform_metrics
    remove_concurrent_index :ci_variables, :key
  end
end
