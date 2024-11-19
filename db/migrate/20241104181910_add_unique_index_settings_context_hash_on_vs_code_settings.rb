# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class AddUniqueIndexSettingsContextHashOnVsCodeSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = 'unique_user_id_setting_type_and_settings_context_hash'
  PREVIOUS_INDEX_NAME = 'unique_user_id_and_setting_type'

  def up
    add_concurrent_index :vs_code_settings, [:user_id, :setting_type, :settings_context_hash], name: INDEX_NAME,
      unique: true
    remove_concurrent_index_by_name :vs_code_settings, name: PREVIOUS_INDEX_NAME
  end

  def down
    add_concurrent_index :vs_code_settings, [:user_id, :setting_type], name: PREVIOUS_INDEX_NAME, unique: true
    remove_concurrent_index_by_name :vs_code_settings, name: INDEX_NAME
  end
end
