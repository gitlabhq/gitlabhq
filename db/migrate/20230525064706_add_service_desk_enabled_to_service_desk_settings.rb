# frozen_string_literal: true

class AddServiceDeskEnabledToServiceDeskSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :service_desk_settings, :service_desk_enabled, :boolean, null: false, default: true
  end
end
