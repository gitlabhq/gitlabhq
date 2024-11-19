# frozen_string_literal: true

class AddLastUsedDateIndexInLastUsage < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = 'index_last_usages_on_last_used_date'

  def up
    add_concurrent_index :catalog_resource_component_last_usages, :last_used_date, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :catalog_resource_component_last_usages, :last_used_date, name: INDEX_NAME
  end
end
