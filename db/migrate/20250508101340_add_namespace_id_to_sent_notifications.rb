# frozen_string_literal: true

class AddNamespaceIdToSentNotifications < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    add_column :sent_notifications, :namespace_id, :bigint, null: false, default: 0 # rubocop:disable Migration/PreventAddingColumns -- Sharding key is a permitted exception
  end
end
