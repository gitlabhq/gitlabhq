# frozen_string_literal: true

class ReplaceIndexForServiceUsageData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_services_on_type_and_id_and_template_when_active'
  NEW_INDEX_NAME = 'index_services_on_type_id_when_active_not_instance_not_template'

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:type, :id], where: 'active = TRUE AND instance = FALSE AND template = FALSE', name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :services, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :services, [:type, :id, :template], where: 'active = TRUE', name: OLD_INDEX_NAME

    remove_concurrent_index :services, NEW_INDEX_NAME
  end
end
