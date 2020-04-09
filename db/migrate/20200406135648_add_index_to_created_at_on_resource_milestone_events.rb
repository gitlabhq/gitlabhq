# frozen_string_literal: true

class AddIndexToCreatedAtOnResourceMilestoneEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_resource_milestone_events_created_at'

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :resource_milestone_events, :created_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :resource_milestone_events, INDEX_NAME
  end
end
