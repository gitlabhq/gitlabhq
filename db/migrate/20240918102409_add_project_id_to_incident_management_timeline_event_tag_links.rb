# frozen_string_literal: true

class AddProjectIdToIncidentManagementTimelineEventTagLinks < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :incident_management_timeline_event_tag_links, :project_id, :bigint
  end
end
