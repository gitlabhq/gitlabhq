class AddDefaultGroupVisibilityToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :default_group_visibility, :integer
    visibility = Settings.gitlab.default_groups_features['visibility_level']
    execute("update application_settings set default_group_visibility = #{visibility}")
  end

  def down
    remove_column :application_settings, :default_group_visibility
  end
end
