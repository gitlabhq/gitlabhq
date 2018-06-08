class AddIndexToCiBuildsArtifactsFile < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      add_concurrent_index :ci_builds, :artifacts_file
    elsif Gitlab::Database.mysql?
      add_concurrent_index :ci_builds, :artifacts_file, length: 20
    end
  end

  def down
    remove_concurrent_index :ci_builds, :artifacts_file
  end
end
