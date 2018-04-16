class AddMissingOnPrimaryToJobArtifactRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :job_artifact_registry, :missing_on_primary, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :job_artifact_registry, :missing_on_primary
  end
end
