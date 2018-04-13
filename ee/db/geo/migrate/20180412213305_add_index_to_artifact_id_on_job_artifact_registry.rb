class AddIndexToArtifactIdOnJobArtifactRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :job_artifact_registry, :artifact_id
  end

  def down
    if index_exists?(:job_artifact_registry, :artifact_id)
      remove_concurrent_index :job_artifact_registry_finder, :artifact_id
    end
  end
end
