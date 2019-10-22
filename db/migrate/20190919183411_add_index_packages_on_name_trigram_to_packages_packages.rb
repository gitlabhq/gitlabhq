# frozen_string_literal: true

class AddIndexPackagesOnNameTrigramToPackagesPackages < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_packages_packages_on_name_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, :name, name: INDEX_NAME, using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end
