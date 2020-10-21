# frozen_string_literal: true

class RemoveInstanceStatisticsVisibilityPrivateFromApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    remove_column :application_settings, :instance_statistics_visibility_private
  end

  def down
    add_column :application_settings, :instance_statistics_visibility_private, :boolean, default: false, null: false
  end
end
