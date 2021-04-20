# frozen_string_literal: true

class AddSourceAndLevelIndexOnNotificationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_WITH_SOURCE_LEVEL_USER_NAME = 'index_notification_settings_on_source_and_level_and_user'
  INDEX_WITH_SOURCE_NAME = 'index_notification_settings_on_source_id_and_source_type'
  INDEX_WITH_USER_NAME = 'index_notification_settings_on_user_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :notification_settings, [:source_id, :source_type, :level, :user_id], name: INDEX_WITH_SOURCE_LEVEL_USER_NAME
    remove_concurrent_index_by_name :notification_settings, INDEX_WITH_SOURCE_NAME # Above index expands this index
    remove_concurrent_index_by_name :notification_settings, INDEX_WITH_USER_NAME # It is redundant as we already have unique index on (user_id, source_id, source_type)
  end

  def down
    add_concurrent_index :notification_settings, [:source_id, :source_type], name: INDEX_WITH_SOURCE_NAME
    add_concurrent_index :notification_settings, [:user_id], name: INDEX_WITH_USER_NAME
    remove_concurrent_index_by_name :notification_settings, INDEX_WITH_SOURCE_LEVEL_USER_NAME
  end
end
