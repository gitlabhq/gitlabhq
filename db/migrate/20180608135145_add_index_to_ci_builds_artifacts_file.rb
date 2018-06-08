class AddIndexToCiBuildsArtifactsFile < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :artifacts_file
  end

  def down
    remove_concurrent_index :ci_builds, :artifacts_file
  end
end
