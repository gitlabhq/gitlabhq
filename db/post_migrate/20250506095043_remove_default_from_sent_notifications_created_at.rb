# frozen_string_literal: true

class RemoveDefaultFromSentNotificationsCreatedAt < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    change_column_default :sent_notifications,
      :created_at,
      from: "'2025-04-02 00:00:00+00'::timestamp with time zone",
      to: nil
  end
end
