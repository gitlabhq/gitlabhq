# frozen_string_literal: true

class IndexUserPreferencesOnDuoDefaultNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_preferences_on_duo_default_namespace_id'

  def up
    add_concurrent_index :user_preferences, :duo_default_namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_preferences, INDEX_NAME
  end
end
