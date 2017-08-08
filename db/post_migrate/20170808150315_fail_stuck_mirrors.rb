class FailStuckMirrors < ActiveRecord::Migration
  DOWNTIME = false

  def up
    stuck_mirrors_query = "import_jid IS NULL AND ((import_status = 'started' AND project_mirror_data.last_update_started_at < :limit) OR (import_status = 'scheduled' AND project_mirror_data.last_update_scheduled_at < :limit))"

    Project.mirror.joins(:mirror_data).where(
      "import_jid IS NULL AND ((import_status = 'started' AND project_mirror_data.last_update_started_at < :limit) OR (import_status = 'scheduled' AND project_mirror_data.last_update_scheduled_at < :limit))",
      { limit: 20.minutes.ago  }
    )
  end

  def down
  end
end
