# frozen_string_literal: true

class CreateIncidentManagementTimelineEventTagLinks < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :incident_management_timeline_event_tag_links do |t|
      t.references :timeline_event,
        null: false,
        index: { name: 'index_im_timeline_event_id' },
        foreign_key: { to_table: :incident_management_timeline_events, column: :timeline_event_id, on_delete: :cascade }

      t.references :timeline_event_tag,
        null: false,
        index: false,
        foreign_key: {
          to_table: :incident_management_timeline_event_tags,
          column: :timeline_event_tag_id,
          on_delete: :cascade
        }

      t.index [:timeline_event_tag_id, :timeline_event_id],
        unique: true,
        name: 'index_im_timeline_event_tags_on_tag_id_and_event_id'

      t.datetime_with_timezone :created_at, null: false
    end
  end

  def down
    drop_table :incident_management_timeline_event_tag_links
  end
end
