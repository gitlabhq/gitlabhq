class DisableMirroringForProjectsWithInvalidMirrorUsers < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<~SQL
      UPDATE projects
      SET mirror = FALSE, mirror_user_id = NULL
      WHERE mirror = true AND
        NOT EXISTS (SELECT 1 FROM users WHERE users.id = projects.mirror_user_id)
    SQL
  end

  def down
  end
end
