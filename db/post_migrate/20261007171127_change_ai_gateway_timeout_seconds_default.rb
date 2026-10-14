# frozen_string_literal: true

class ChangeAiGatewayTimeoutSecondsDefault < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    change_column_default :application_settings, :ai_gateway_timeout_seconds, from: 60, to: 120
  end

  def down
    change_column_default :application_settings, :ai_gateway_timeout_seconds, from: 120, to: 60
  end
end
