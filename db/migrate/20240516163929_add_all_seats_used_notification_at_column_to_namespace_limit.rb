# frozen_string_literal: true

class AddAllSeatsUsedNotificationAtColumnToNamespaceLimit < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :namespace_limits, :last_seat_all_used_seats_notification_at, :datetime_with_timezone
  end
end
