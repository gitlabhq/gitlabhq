# frozen_string_literal: true

class AddIndexToPackageCreator < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_packages_on_creator_id'

  def up
    add_concurrent_index :packages_packages, :creator_id, name: INDEX_NAME
    add_concurrent_foreign_key(:packages_packages, :users, column: :creator_id, on_delete: :nullify)
  end

  def down
    remove_foreign_key_if_exists(:packages_packages, :users, column: :creator_id)
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end
