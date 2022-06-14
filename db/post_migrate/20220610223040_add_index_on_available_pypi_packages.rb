# frozen_string_literal: true

class AddIndexOnAvailablePypiPackages < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_on_available_pypi_packages'

  def up
    add_concurrent_index :packages_packages,
      [:project_id, :id],
      where: "status IN (0,1) AND package_type = 5 AND version IS NOT NULL",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
