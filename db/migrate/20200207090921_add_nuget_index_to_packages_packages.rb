# frozen_string_literal: true

class AddNugetIndexToPackagesPackages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_packages_project_id_name_partial_for_nuget'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, [:project_id, :name], name: INDEX_NAME, where: "name <> 'NuGet.Temporary.Package' AND version is not null AND package_type = 4"
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
