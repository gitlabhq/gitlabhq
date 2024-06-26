# frozen_string_literal: true

class AddIndexOnProjectFeatureProjectIdWhenPublicPackageRegistry < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  INDEX_NAME = 'index_project_features_on_project_id_on_public_package_registry'
  PROJECT_FEATURES_PUBLIC = 30

  def up
    add_concurrent_index :project_features, :project_id,
      where: "package_registry_access_level = #{PROJECT_FEATURES_PUBLIC}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_features, INDEX_NAME
  end
end
