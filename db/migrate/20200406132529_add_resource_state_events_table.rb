# frozen_string_literal: true

class AddResourceStateEventsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :resource_state_events, id: :bigserial do |t|
      t.bigint :user_id, null: false
      t.bigint :issue_id, null: true
      t.bigint :merge_request_id, null: true

      t.datetime_with_timezone :created_at, null: false
      t.integer :state, limit: 2, null: false

      t.index [:issue_id, :created_at], name: 'index_resource_state_events_on_issue_id_and_created_at'
      t.index [:user_id], name: 'index_resource_state_events_on_user_id'
      t.index [:merge_request_id], name: 'index_resource_state_events_on_merge_request_id'
    end
  end
end
