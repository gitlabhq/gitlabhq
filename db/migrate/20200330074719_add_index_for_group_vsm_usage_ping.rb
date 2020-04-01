# frozen_string_literal: true

class AddIndexForGroupVsmUsagePing < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_analytics_cycle_analytics_group_stages_custom_only'

  disable_ddl_transaction!

  def up
    add_concurrent_index :analytics_cycle_analytics_group_stages, :id, where: 'custom = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :analytics_cycle_analytics_group_stages, INDEX_NAME
  end
end
