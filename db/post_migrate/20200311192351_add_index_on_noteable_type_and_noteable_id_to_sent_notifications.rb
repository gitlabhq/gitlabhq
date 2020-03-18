# frozen_string_literal: true

class AddIndexOnNoteableTypeAndNoteableIdToSentNotifications < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_sent_notifications_on_noteable_type_noteable_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sent_notifications,
      [:noteable_id],
      name: INDEX_NAME,
      where: "noteable_type = 'Issue'"
  end

  def down
    remove_concurrent_index_by_name :sent_notifications, INDEX_NAME
  end
end
