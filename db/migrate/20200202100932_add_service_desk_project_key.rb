# frozen_string_literal: true

class AddServiceDeskProjectKey < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :service_desk_settings, :project_key, :string, limit: 255
  end
end
