# frozen_string_literal: true

class RemovePartialIndexFromCiBuildsArtifactsFile < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'partial_index_ci_builds_on_id_with_legacy_artifacts'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME)
  end

  def down
    add_concurrent_index(:ci_builds, :id, where: "artifacts_file <> ''", name: INDEX_NAME)
  end
end
