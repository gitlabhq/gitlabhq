# frozen_string_literal: true

class AddCreatedAtToSentNotifications < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def up
    add_timestamps_with_timezone :sent_notifications, # rubocop:disable Migration/PreventAddingColumns -- Necessary for partitioning
      columns: %i[created_at],
      null: false,
      default: "'2025-04-02 00:00:00.000000+00'::timestamp with time zone"
  end

  def down
    remove_timestamps :sent_notifications, columns: %i[created_at]
  end
end
