# frozen_string_literal: true

class IndexIncidentManagementTimelineEventTagLinksOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_incident_management_timeline_event_tag_links_on_project_id'

  def up
    add_concurrent_index :incident_management_timeline_event_tag_links, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :incident_management_timeline_event_tag_links, INDEX_NAME
  end
end
