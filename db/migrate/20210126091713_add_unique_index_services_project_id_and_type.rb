# frozen_string_literal: true

class AddUniqueIndexServicesProjectIdAndType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_services_on_project_id_and_type_unique'

  def up
    add_concurrent_index :services, [:project_id, :type], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :services, name: INDEX_NAME
  end
end
