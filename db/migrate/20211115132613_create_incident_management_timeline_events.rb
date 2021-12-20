# frozen_string_literal: true

class CreateIncidentManagementTimelineEvents < Gitlab::Database::Migration[1.0]
  def up
    create_table :incident_management_timeline_events do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :occurred_at, null: false
      t.bigint :project_id, null: false
      t.bigint :author_id
      t.bigint :issue_id, null: false
      t.bigint :updated_by_user_id
      t.bigint :promoted_from_note_id
      t.integer :cached_markdown_version
      t.boolean :editable, null: false, default: false
      t.text :note, limit: 10_000, null: false
      t.text :note_html, limit: 10_000, null: false
      t.text :action, limit: 128, null: false

      t.index :project_id, name: 'index_im_timeline_events_project_id'
      t.index :author_id, name: 'index_im_timeline_events_author_id'
      t.index :issue_id, name: 'index_im_timeline_events_issue_id'
      t.index :updated_by_user_id, name: 'index_im_timeline_events_updated_by_user_id'
      t.index :promoted_from_note_id, name: 'index_im_timeline_events_promoted_from_note_id'
    end
  end

  def down
    drop_table :incident_management_timeline_events
  end
end
