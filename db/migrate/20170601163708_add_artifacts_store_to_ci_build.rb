class AddArtifactsStoreToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_builds, :artifacts_file_store, :integer, default: 1)
    add_column_with_default(:ci_builds, :artifacts_metadata_store, :integer, default: 1)
  end

  def down
    remove_column(:ci_builds, :artifacts_file_store)
    remove_column(:ci_builds, :artifacts_metadata_store)
  end
end
