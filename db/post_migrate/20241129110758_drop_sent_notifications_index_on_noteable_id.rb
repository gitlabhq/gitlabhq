# frozen_string_literal: true

class DropSentNotificationsIndexOnNoteableId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME = 'index_sent_notifications_on_noteable_type_noteable_id'

  def up
    remove_concurrent_index_by_name :sent_notifications, INDEX_NAME
  end

  def down
    add_concurrent_index :sent_notifications, :noteable_id, where: "noteable_type = 'Issue'", name: INDEX_NAME
  end
end
