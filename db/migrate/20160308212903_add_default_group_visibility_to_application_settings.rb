#Create visibility level field on DB
#Sets default_visibility_level to value on settings if not restricted
#If value is restricted takes higher visibility level allowed

class AddDefaultGroupVisibilityToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :default_group_visibility, :integer
    execute("update application_settings set default_group_visibility = #{allowed_visibility_level}")
  end

  def down
    remove_column :application_settings, :default_group_visibility
  end

  private
  def allowed_visibility_level
    default_visibility = Settings.gitlab.default_groups_features['visibility_level']
    restricted_levels  = current_application_settings.restricted_visibility_levels
    return default_visibility unless restricted_levels.present?

    if restricted_levels.include?(default_visibility)
      Gitlab::VisibilityLevel.values.select{ |vis_level| vis_level unless restricted_levels.include?(vis_level) }.last
    else
      default_visibility
    end
  end
end
