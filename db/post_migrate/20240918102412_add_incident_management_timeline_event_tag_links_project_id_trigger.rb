# frozen_string_literal: true

class AddIncidentManagementTimelineEventTagLinksProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :incident_management_timeline_event_tag_links,
      sharding_key: :project_id,
      parent_table: :incident_management_timeline_event_tags,
      parent_sharding_key: :project_id,
      foreign_key: :timeline_event_tag_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :incident_management_timeline_event_tag_links,
      sharding_key: :project_id,
      parent_table: :incident_management_timeline_event_tags,
      parent_sharding_key: :project_id,
      foreign_key: :timeline_event_tag_id
    )
  end
end
