# frozen_string_literal: true

class AddIndexCdArtifactSourcesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_artifact_sources_on_project_id'

  def up
    add_concurrent_index :cd_artifact_sources, :project_id, name: INDEX_NAME, where: 'project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :cd_artifact_sources, INDEX_NAME
  end
end
