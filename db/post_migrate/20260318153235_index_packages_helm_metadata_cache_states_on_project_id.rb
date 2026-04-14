# frozen_string_literal: true

class IndexPackagesHelmMetadataCacheStatesOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_helm_metadata_cache_states_on_project_id'

  def up
    add_concurrent_index :packages_helm_metadata_cache_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_helm_metadata_cache_states, INDEX_NAME
  end
end
