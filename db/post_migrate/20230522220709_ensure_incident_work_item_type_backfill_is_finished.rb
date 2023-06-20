# frozen_string_literal: true

class EnsureIncidentWorkItemTypeBackfillIsFinished < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillWorkItemTypeIdForIssues'
  INCIDENT_ENUM_TYPE = 1

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  def up
    incident_work_item_type = MigrationWorkItemType.find_by(namespace_id: nil, base_type: INCIDENT_ENUM_TYPE)

    if incident_work_item_type.blank?
      say(
        'Incident work item type not found. Make sure the work_item_types table is populated' \
        'before running this migration'
      )
      return
    end

    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :issues,
      column_name: :id,
      job_arguments: [INCIDENT_ENUM_TYPE, incident_work_item_type.id]
    )
  end

  def down
    # no-op
  end
end
