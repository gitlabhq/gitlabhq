# Create visibility level field on DB
# Sets default_visibility_level to value on settings if not restricted
# If value is restricted takes higher visibility level allowed

class AddDefaultGroupVisibilityToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :default_group_visibility, :integer
    # Unfortunately, this can't be a `default`, since we don't want the configuration specific
    # `allowed_visibility_level` to end up in schema.rb
    execute("UPDATE application_settings SET default_group_visibility = #{allowed_visibility_level}")
  end

  def down
    remove_column :application_settings, :default_group_visibility
  end

  private

  def allowed_visibility_level
    application_settings = select_one("SELECT restricted_visibility_levels FROM application_settings ORDER BY id DESC LIMIT 1")
    if application_settings
      restricted_visibility_levels = YAML.safe_load(application_settings["restricted_visibility_levels"]) rescue nil
    end
    restricted_visibility_levels ||= []

    allowed_levels = Gitlab::VisibilityLevel.values - restricted_visibility_levels
    allowed_levels.max
  end
end
