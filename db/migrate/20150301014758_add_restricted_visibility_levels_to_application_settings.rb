class AddRestrictedVisibilityLevelsToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :restricted_visibility_levels, :text
  end
end
