# frozen_string_literal: true

class AddIndexUniqueSettingTypeOnVsCodeSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_user_id_and_setting_type'
  PREVIOUS_INDEX_NAME = 'index_vs_code_settings_on_user_id'

  def up
    remove_concurrent_index_by_name :vs_code_settings, name: PREVIOUS_INDEX_NAME
    add_concurrent_index :vs_code_settings, [:user_id, :setting_type], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :vs_code_settings, name: INDEX_NAME
    add_concurrent_index :vs_code_settings, [:user_id], name: PREVIOUS_INDEX_NAME
  end
end
