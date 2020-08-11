# frozen_string_literal: true

class CreateResourceIterationEventsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :resource_iteration_events do |t|
      t.bigint :user_id, null: false, index: { name: 'index_resource_iteration_events_on_user_id' }
      t.bigint :issue_id, null: true, index: { name: 'index_resource_iteration_events_on_issue_id' }
      t.bigint :merge_request_id, null: true, index: { name: 'index_resource_iteration_events_on_merge_request_id' }
      t.bigint :iteration_id, index: { name: 'index_resource_iteration_events_on_iteration_id' }
      t.datetime_with_timezone :created_at, null: false
      t.integer :action, limit: 2, null: false
    end
  end
end
