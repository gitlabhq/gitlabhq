# frozen_string_literal: true

class AddTicketsConfidentialByDefaultToServiceDeskSettings < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  enable_lock_retries!

  def change
    add_column :service_desk_settings, :tickets_confidential_by_default, :boolean, default: true, null: false
  end
end
