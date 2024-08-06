# frozen_string_literal: true

class AddIndexToGroupCrmSettingsSourceGroupId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = 'index_group_crm_settings_on_source_group_id'

  def up
    add_concurrent_index :group_crm_settings, :source_group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :group_crm_settings, INDEX_NAME
  end
end
