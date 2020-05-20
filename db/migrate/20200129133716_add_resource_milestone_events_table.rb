# frozen_string_literal: true

class AddResourceMilestoneEventsTable < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :resource_milestone_events, id: :bigserial do |t|
      t.references :user, null: false, foreign_key: { on_delete: :nullify },
                   index: { name: 'index_resource_milestone_events_on_user_id' }
      t.references :issue, null: true, foreign_key: { on_delete: :cascade },
                   index: { name: 'index_resource_milestone_events_on_issue_id' }
      t.references :merge_request, null: true, foreign_key: { on_delete: :cascade },
                   index: { name: 'index_resource_milestone_events_on_merge_request_id' }
      t.references :milestone, foreign_key: { on_delete: :cascade },
                   index: { name: 'index_resource_milestone_events_on_milestone_id' }

      t.integer :action, limit: 2, null: false
      t.integer :state, limit: 2, null: false
      t.integer :cached_markdown_version
      t.text :reference
      t.text :reference_html
      t.datetime_with_timezone :created_at, null: false
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
