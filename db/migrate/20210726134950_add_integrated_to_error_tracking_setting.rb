# frozen_string_literal: true

class AddIntegratedToErrorTrackingSetting < ActiveRecord::Migration[6.1]
  def up
    add_column :project_error_tracking_settings, :integrated, :boolean, null: false, default: false
  end

  def down
    remove_column :project_error_tracking_settings, :integrated
  end
end
