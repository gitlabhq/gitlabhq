# frozen_string_literal: true

class AddIdCreatedAtIndexToPackages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_packages_on_id_and_created_at'

  def up
    add_concurrent_index :packages_packages, [:id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end
