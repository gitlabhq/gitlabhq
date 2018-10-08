class AddPartialIndexToCiBuildsArtifactsFile < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'partial_index_ci_builds_on_id_with_legacy_artifacts'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_builds, :id, where: "artifacts_file <> ''", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME)
  end
end
