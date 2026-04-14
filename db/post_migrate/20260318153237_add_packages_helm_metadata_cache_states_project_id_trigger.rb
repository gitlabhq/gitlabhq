# frozen_string_literal: true

class AddPackagesHelmMetadataCacheStatesProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_helm_metadata_cache_states,
      sharding_key: :project_id,
      parent_table: :packages_helm_metadata_caches,
      parent_sharding_key: :project_id,
      foreign_key: :packages_helm_metadata_cache_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_helm_metadata_cache_states,
      sharding_key: :project_id,
      parent_table: :packages_helm_metadata_caches,
      parent_sharding_key: :project_id,
      foreign_key: :packages_helm_metadata_cache_id
    )
  end
end
