class RemoveGeoPrimarySystemHook < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # Older versions of GitLab added a system hook for the primary Geo node.
  # This would cause all events to be fired for the primary as well.
  def up
    return unless geo_enabled?

    execute <<-SQL
      DELETE FROM web_hooks WHERE
      type = 'SystemHook' AND
      id IN (
      SELECT system_hook_id FROM geo_nodes WHERE
        "primary" = #{true_value}
      );
    SQL
  end

  def geo_enabled?
    select_all("SELECT 1 FROM geo_nodes").present?
  end
end
