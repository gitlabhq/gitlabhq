class RemovePushEventsFromGeoPrimarySystemHook < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # Older version of Geo added push and tag push events to the
  # primary system hook. This would cause unnecessary hooks to be
  # fired.
  def up
    return unless geo_enabled?

    execute <<-SQL
      UPDATE web_hooks
      SET push_events = false, tag_push_events = false WHERE
      type = 'SystemHook' AND
      id = (
      SELECT system_hook_id FROM geo_nodes WHERE
        host = #{quote(Gitlab.config.gitlab.host)} AND
        port = #{quote(Gitlab.config.gitlab.port)} AND
        relative_url_root = #{quote(Gitlab.config.gitlab.relative_url_root)});
    SQL
  end

  def geo_enabled?
    select_all("SELECT 1 FROM geo_nodes").present?
  end
end
