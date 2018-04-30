class MigrateMirrorAttributesDataFromProjectsToImportState < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    Project.joins('INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id').each_batch do |batch|
      start, stop = batch.pluck('MIN(projects.id), MAX(projects.id)').first

      execute <<~SQL
        UPDATE project_mirror_data
        SET
          status = proj.import_status,
          jid = proj.import_jid,
          last_update_at = proj.mirror_last_update_at,
          last_successful_update_at = proj.mirror_last_successful_update_at,
          last_error = proj.import_error
        FROM projects proj
        WHERE proj.id = project_id
        AND proj.mirror = TRUE
        AND proj.id >= #{start}
        AND proj.id < #{stop}
      SQL

      execute <<~SQL
        UPDATE projects
        SET import_status = NULL
        WHERE mirror = TRUE
        AND id >= #{start}
        AND id < #{stop}
      SQL
    end
  end

  def down
    Project.joins('INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id').each_batch do |batch|
      start, stop = batch.pluck('MIN(projects.id), MAX(projects.id)').first

      execute <<~SQL
        UPDATE projects
        SET
          projects.import_status = import_state.status,
          projects.import_jid = import_state.jid,
          projects.mirror_last_update_at = import_state.last_update_at,
          projects.mirror_last_successful_update_at = import_state.last_successful_update_at,
          projects.import_error = import_state.last_error
        FROM project_mirror_data import_state
        WHERE import_state.project_id = projects.id
        AND projects.mirror = TRUE
        AND projects.id >= #{start}
        AND projects.id < #{stop}
      SQL

      execute <<~SQL
        UPDATE project_mirror_data
        SET
          status = NULL
        FROM projects proj
        WHERE proj.id = project_id
        AND proj.mirror = TRUE
        AND proj.id >= #{start}
        AND proj.id < #{stop}
      SQL
    end
  end
end
