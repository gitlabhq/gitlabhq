# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGeoJobArtifactDeletedEventsForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_job_artifact_deleted_events,
                               column: :job_artifact_deleted_event_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :geo_event_log, column: :job_artifact_deleted_event_id
  end
end
