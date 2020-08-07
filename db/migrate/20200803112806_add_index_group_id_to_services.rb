# frozen_string_literal: true

class AddIndexGroupIdToServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_services_on_unique_group_id_and_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:group_id, :type], unique: true, name: INDEX_NAME

    add_concurrent_foreign_key :services, :namespaces, column: :group_id
  end

  def down
    remove_foreign_key_if_exists :services, column: :group_id

    remove_concurrent_index_by_name :services, INDEX_NAME
  end
end
