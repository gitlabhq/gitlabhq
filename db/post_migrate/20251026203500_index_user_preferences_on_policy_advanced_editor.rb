# frozen_string_literal: true

class IndexUserPreferencesOnPolicyAdvancedEditor < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_preferences_on_policy_advanced_editor'
  INDEX_WHERE = 'policy_advanced_editor = TRUE'

  def up
    add_concurrent_index :user_preferences, :policy_advanced_editor, where: INDEX_WHERE, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_preferences, INDEX_NAME
  end
end
