# frozen_string_literal: true

class AddServiceDeskProjectKey < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :service_desk_settings, :project_key, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
