# frozen_string_literal: true

class CreateIncidentManagementTimelineEventTags < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :incident_management_timeline_event_tags do |t|
      t.timestamps_with_timezone null: false
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.text :name, limit: 255, null: false

      t.index [:project_id, :name], unique: true, name: 'index_im_timeline_event_tags_name_project_id'
    end
  end

  def down
    drop_table :incident_management_timeline_event_tags
  end
end
