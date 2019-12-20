# frozen_string_literal: true

class AddServiceDeskUsername < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :service_desk_settings, :outgoing_name, :string, limit: 255
  end
end
