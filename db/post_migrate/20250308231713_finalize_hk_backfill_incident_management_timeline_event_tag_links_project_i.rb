# frozen_string_literal: true

class FinalizeHkBackfillIncidentManagementTimelineEventTagLinksProjectI < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIncidentManagementTimelineEventTagLinksProjectId',
      table_name: :incident_management_timeline_event_tag_links,
      column_name: :id,
      job_arguments: [:project_id, :incident_management_timeline_event_tags, :project_id, :timeline_event_tag_id],
      finalize: true
    )
  end

  def down; end
end
