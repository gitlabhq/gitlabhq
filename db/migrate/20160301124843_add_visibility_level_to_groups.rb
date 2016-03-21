class AddVisibilityLevelToGroups < ActiveRecord::Migration
  def up
    add_column :namespaces, :visibility_level, :integer, null: false, default: Gitlab::VisibilityLevel::PUBLIC
    add_index :namespaces, :visibility_level

    # Unfortunately, this is needed on top of the `default`, since we don't want the configuration specific
    # `allowed_visibility_level` to end up in schema.rb
    if allowed_visibility_level < Gitlab::VisibilityLevel::PUBLIC
      execute("UPDATE namespaces SET visibility_level = #{allowed_visibility_level}")
    end
  end

  def down
    remove_column :namespaces, :visibility_level
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
