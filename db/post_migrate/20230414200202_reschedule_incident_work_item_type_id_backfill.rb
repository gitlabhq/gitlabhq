# frozen_string_literal: true

class RescheduleIncidentWorkItemTypeIdBackfill < Gitlab::Database::Migration[2.1]
  MIGRATION = 'BackfillWorkItemTypeIdForIssues'
  BATCH_SIZE = 10_000
  MAX_BATCH_SIZE = 30_000
  SUB_BATCH_SIZE = 50
  INTERVAL = 2.minutes
  INCIDENT_ENUM_TYPE = 1

  restrict_gitlab_migration gitlab_schema: :gitlab_main

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

    delete_batched_background_migration(MIGRATION, :issues, :id, [INCIDENT_ENUM_TYPE, incident_work_item_type.id])

    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      INCIDENT_ENUM_TYPE,
      incident_work_item_type.id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    # no-op
    # no point on reverting this migration since UP is destructive
    # (it will delete the originally scheduled job)
  end
end
