#Create visibility level field on DB
#Sets default_visibility_level to value on settings if not restricted
#If value is restricted takes higher visibility level allowed

class AddDefaultGroupVisibilityToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :default_group_visibility, :integer
    execute("UPDATE application_settings SET default_group_visibility = #{allowed_visibility_level}")
  end

  def down
    remove_column :application_settings, :default_group_visibility
  end

  private

  def allowed_visibility_level
    # TODO: Don't use `current_application_settings`
    allowed_levels = Gitlab::VisibilityLevel.values - current_application_settings.restricted_visibility_levels
    allowed_levels.max
  end
end
