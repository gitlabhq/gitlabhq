# frozen_string_literal: true

class AddExpiryNotificationColumnsToDeployTokens < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    add_column :deploy_tokens, :seven_days_notification_sent_at, :datetime_with_timezone
    add_column :deploy_tokens, :thirty_days_notification_sent_at, :datetime_with_timezone
    add_column :deploy_tokens, :sixty_days_notification_sent_at, :datetime_with_timezone
  end

  def down
    remove_column :deploy_tokens, :seven_days_notification_sent_at
    remove_column :deploy_tokens, :thirty_days_notification_sent_at
    remove_column :deploy_tokens, :sixty_days_notification_sent_at
  end
end
