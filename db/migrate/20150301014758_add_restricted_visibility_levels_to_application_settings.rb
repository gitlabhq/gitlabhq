class AddRestrictedVisibilityLevelsToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :restricted_visibility_levels, :text
  end
end
