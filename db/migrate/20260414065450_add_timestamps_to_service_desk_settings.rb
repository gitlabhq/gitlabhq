# frozen_string_literal: true

class AddTimestampsToServiceDeskSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_timestamps_with_timezone :service_desk_settings, null: false, default: -> { 'NOW()' }
  end
end
