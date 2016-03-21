class AddVisibilityLevelToGroups < ActiveRecord::Migration
  def change
    #All groups public by default
    add_column :namespaces, :visibility_level, :integer, null: false, default: allowed_visibility_level
  end

  def allowed_visibility_level
    # TODO: Don't use `current_application_settings`
    allowed_levels = Gitlab::VisibilityLevel.values - current_application_settings.restricted_visibility_levels
    allowed_levels.max
  end
end
