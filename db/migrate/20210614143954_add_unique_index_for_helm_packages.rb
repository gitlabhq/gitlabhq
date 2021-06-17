# frozen_string_literal: true

class AddUniqueIndexForHelmPackages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_packages_on_project_id_name_version_unique_when_helm'
  PACKAGE_TYPE_HELM = 11

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, [:project_id, :name, :version], unique: true, where: "package_type = #{PACKAGE_TYPE_HELM}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
