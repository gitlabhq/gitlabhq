# frozen_string_literal: true

class TruncateTimelineEventTagsTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    execute('TRUNCATE TABLE incident_management_timeline_event_tags, incident_management_timeline_event_tag_links')
  end

  def down
    # no-op
  end
end
