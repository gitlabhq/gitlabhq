# frozen_string_literal: true

class AddNotificationColsToPersonalAccessTokens < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :personal_access_tokens, :seven_days_notification_sent_at, :datetime_with_timezone
    # rubocop:enable Migration/PreventAddingColumns
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :personal_access_tokens, :thirty_days_notification_sent_at, :datetime_with_timezone
    # rubocop:enable Migration/PreventAddingColumns
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :personal_access_tokens, :sixty_days_notification_sent_at, :datetime_with_timezone
    # rubocop:enable Migration/PreventAddingColumns
  end

  def down
    remove_column :personal_access_tokens, :seven_days_notification_sent_at
    remove_column :personal_access_tokens, :thirty_days_notification_sent_at
    remove_column :personal_access_tokens, :sixty_days_notification_sent_at
  end
end
