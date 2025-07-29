# frozen_string_literal: true

class RemoveSentNotificationsNamespaceIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_sent_notifications_on_namespace_id_and_id'

  milestone '18.3'

  def up
    # Only created async in .com, no need to remove synchronously
    prepare_async_index_removal :sent_notifications, [:namespace_id, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :sent_notifications, [:namespace_id, :id], name: INDEX_NAME
  end
end
