# frozen_string_literal: true

class RemoveJobArtifactDeletedEventTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    drop_table :geo_job_artifact_deleted_events
  end

  def down
    create_table :geo_job_artifact_deleted_events, id: :bigserial do |t|
      t.bigint :job_artifact_id, null: false, index: true
      t.string :file_path, null: false
    end
  end
end
