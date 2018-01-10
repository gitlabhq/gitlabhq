# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateGeoJobArtifactDeletedEvent < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_job_artifact_deleted_events, id: :bigserial do |t|
      t.references :job_artifact, references: :ci_job_artifacts, index: true, foreign_key: false, null: false
      t.string :file_path, null: false
    end

    add_column :geo_event_log, :job_artifact_deleted_event_id, :integer, limit: 8
  end
end
