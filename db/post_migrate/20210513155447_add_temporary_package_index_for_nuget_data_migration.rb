# frozen_string_literal: true

class AddTemporaryPackageIndexForNugetDataMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'tmp_index_packages_on_id_where_nuget_default_temp_package'
  INDEX_CONDITION = "package_type = 4 AND name = 'NuGet.Temporary.Package' AND status = 0"

  disable_ddl_transaction!

  def up
    # this index is used in 20210513155546_backfill_nuget_temporary_packages_to_processing_status
    add_concurrent_index :packages_packages, :id, where: INDEX_CONDITION, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
