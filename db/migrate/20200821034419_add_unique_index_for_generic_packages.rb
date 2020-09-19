# frozen_string_literal: true

class AddUniqueIndexForGenericPackages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_packages_on_project_id_name_version_unique_when_generic'
  PACKAGE_TYPE_GENERIC = 7

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, [:project_id, :name, :version], unique: true, where: "package_type = #{PACKAGE_TYPE_GENERIC}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end
