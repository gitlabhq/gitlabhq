# frozen_string_literal: true

class AddExpireNotificationDeliveredToPersonalAccessTokens < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :personal_access_tokens, :expire_notification_delivered, :boolean, default: false
  end

  def down
    remove_column :personal_access_tokens, :expire_notification_delivered
  end
end
