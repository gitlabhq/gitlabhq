# frozen_string_literal: true

class UpdateObjectStorageKeyUniqueIndexOnPackagesHelmMetadataCaches < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :packages_helm_metadata_caches
  NEW_INDEX_NAME = :idx_pks_helm_metadata_caches_on_object_storage_key_project_id
  OLD_INDEX_NAME = :index_packages_helm_metadata_caches_on_object_storage_key

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[object_storage_key project_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[object_storage_key],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
