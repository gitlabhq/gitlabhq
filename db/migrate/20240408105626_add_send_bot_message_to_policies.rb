# frozen_string_literal: true

class AddSendBotMessageToPolicies < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.0'

  def change
    add_column :scan_result_policies, :send_bot_message, :jsonb, null: false, default: {}
  end
end
