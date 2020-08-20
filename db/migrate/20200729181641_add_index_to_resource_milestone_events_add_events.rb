# frozen_string_literal: true

class AddIndexToResourceMilestoneEventsAddEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_resource_milestone_events_on_milestone_id_and_add_action'
  ADD_ACTION = '1'

  def up
    # Index add milestone events
    add_concurrent_index :resource_milestone_events, :milestone_id, where: "action = #{ADD_ACTION}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index :resource_milestone_events, :milestone_id, name: INDEX_NAME
  end
end
