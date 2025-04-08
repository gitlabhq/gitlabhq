# frozen_string_literal: true

class AddIncidentManagementTimelineEventTagLinksProjectIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_not_null_constraint :incident_management_timeline_event_tag_links, :project_id
  end

  def down
    remove_not_null_constraint :incident_management_timeline_event_tag_links, :project_id
  end
end
