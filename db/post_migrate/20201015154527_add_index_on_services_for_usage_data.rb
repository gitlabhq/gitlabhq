# frozen_string_literal: true

class AddIndexOnServicesForUsageData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_services_on_type_id_when_active_and_project_id_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:type, :id], where: 'active = TRUE AND project_id IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :services, INDEX_NAME
  end
end
