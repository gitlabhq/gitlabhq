class MigrateImportAttributesDataFromProjectsToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  class ProjectImportState < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_mirror_data'
  end

  def up
    Project.where.not(import_status: nil).each_batch do |batch|
      start, stop = batch.pluck('MIN(id), MAX(id)').first

      execute <<~SQL
        INSERT INTO project_mirror_data (project_id, status, jid, last_update_at, last_successful_update_at, last_error)
        SELECT id, import_status, import_jid, mirror_last_update_at, mirror_last_successful_update_at, import_error
        FROM projects proj
        WHERE proj.import_status IS NOT NULL
        AND proj.id >= #{start}
        AND proj.id < #{stop}
      SQL

      execute <<~SQL
        UPDATE projects
        SET import_status = NULL
        WHERE import_status IS NOT NULL
        AND id >= #{start}
        AND id < #{stop}
      SQL
    end
  end

  def down
    ProjectImportState.where.not(status: nil).each_batch do |batch|
      start, stop = batch.pluck('MIN(id), MAX(id)').first

      execute <<~SQL
        UPDATE projects
        SET
          import_status = mirror_data.status,
          import_jid = mirror_data.jid,
          mirror_last_update_at = mirror_data.last_update_at,
          mirror_last_successful_update_at = mirror_data.last_successful_update_at,
          import_error = mirror_data.last_error
        FROM project_mirror_data mirror_data
        WHERE mirror_data.project_id = projects.id
        AND mirror_data.status IS NOT NULL
        AND mirror_data.id >= #{start}
        AND mirror_data.id < #{stop}
      SQL

      execute <<~SQL
        UPDATE project_mirror_data
        SET status = NULL
        WHERE status IS NOT NULL
        AND id >= #{start}
        AND id < #{stop}
      SQL
    end
  end
end
