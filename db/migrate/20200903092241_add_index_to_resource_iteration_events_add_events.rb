# frozen_string_literal: true

class AddIndexToResourceIterationEventsAddEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_resource_iteration_events_on_iteration_id_and_add_action'
  ADD_ACTION = '1'

  def up
    # Index add iteration events
    add_concurrent_index :resource_iteration_events, :iteration_id, where: "action = #{ADD_ACTION}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index :resource_iteration_events, :iteration_id, name: INDEX_NAME
  end
end
