# frozen_string_literal: true

class RemoveIndexServiceForUsageData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_services_on_type_id_when_active_not_instance_not_template'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :services, INDEX_NAME
  end

  def down
    add_concurrent_index :services, [:type, :id], where: 'active = TRUE AND instance = FALSE AND template = FALSE', name: INDEX_NAME
  end
end
