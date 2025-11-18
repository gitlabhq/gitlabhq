# frozen_string_literal: true

class AddAiGatewayTimeoutSecondsToAiSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  def up
    add_column :ai_settings, :ai_gateway_timeout_seconds, :integer, default: 60, if_not_exists: true
  end

  def down
    remove_column :ai_settings, :ai_gateway_timeout_seconds, if_exists: true
  end
end
