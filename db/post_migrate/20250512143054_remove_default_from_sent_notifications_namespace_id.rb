# frozen_string_literal: true

class RemoveDefaultFromSentNotificationsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    change_column_default :sent_notifications, :namespace_id, from: 0, to: nil
  end
end
