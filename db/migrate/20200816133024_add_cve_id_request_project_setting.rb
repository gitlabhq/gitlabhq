# frozen_string_literal: true

class AddCveIdRequestProjectSetting < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :project_settings, :cve_id_request_enabled, :boolean, default: true, null: false
  end

  def down
    remove_column :project_settings, :cve_id_request_enabled
  end
end
