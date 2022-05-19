# frozen_string_literal: true

class RemoveJobArtifactDeprecatedGeoFields < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :geo_event_log, :job_artifact_deleted_event_id, :bigint
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(:geo_event_log, :job_artifact_deleted_event_id)
        add_column(:geo_event_log, :job_artifact_deleted_event_id, :bigint)
      end
    end

    add_concurrent_foreign_key :geo_event_log, :geo_job_artifact_deleted_events,
                               column: :job_artifact_deleted_event_id,
                               name: 'fk_176d3fbb5d',
                               on_delete: :cascade

    add_concurrent_index :geo_event_log,
                         :job_artifact_deleted_event_id,
                         name: 'index_geo_event_log_on_job_artifact_deleted_event_id',
                         where: "(job_artifact_deleted_event_id IS NOT NULL)"
  end
end
