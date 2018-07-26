class MigrateMirrorAttributesDataFromProjectsToImportState < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'

    scope :join_mirror_data, -> { joins('INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id') }
  end

  def up
    Project.join_mirror_data.each_batch do |batch|
      start, stop = batch.pluck('MIN(projects.id), MAX(projects.id)').first

      if Gitlab::Database.mysql?
        execute <<~SQL
          UPDATE project_mirror_data, projects
          SET
            project_mirror_data.status = projects.import_status,
            project_mirror_data.jid = projects.import_jid,
            project_mirror_data.last_update_at = projects.mirror_last_update_at,
            project_mirror_data.last_successful_update_at = projects.mirror_last_successful_update_at,
            project_mirror_data.last_error = projects.import_error
          WHERE projects.id = project_mirror_data.project_id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL
      else
        execute <<~SQL
          UPDATE project_mirror_data
          SET
            status = projects.import_status,
            jid = projects.import_jid,
            last_update_at = projects.mirror_last_update_at,
            last_successful_update_at = projects.mirror_last_successful_update_at,
            last_error = projects.import_error
          FROM projects
          WHERE projects.id = project_id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL
      end

      execute <<~SQL
        UPDATE projects
        SET import_status = 'none'
        WHERE mirror = TRUE
        AND id BETWEEN #{start} AND #{stop}
      SQL
    end
  end

  def down
    Project.join_mirror_data.each_batch do |batch|
      start, stop = batch.pluck('MIN(projects.id), MAX(projects.id)').first

      if Gitlab::Database.mysql?
        execute <<~SQL
          UPDATE projects, project_mirror_data
          SET
            projects.import_status = project_mirror_data.status,
            projects.import_jid = project_mirror_data.jid,
            projects.mirror_last_update_at = project_mirror_data.last_update_at,
            projects.mirror_last_successful_update_at = project_mirror_data.last_successful_update_at,
            projects.import_error = project_mirror_data.last_error
          WHERE project_mirror_data.project_id = projects.id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL

        execute <<~SQL
          UPDATE project_mirror_data, projects
          SET project_mirror_data.status = 'none'
          WHERE projects.id = project_mirror_data.project_id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL
      else
        execute <<~SQL
          UPDATE projects
          SET
            import_status = project_mirror_data.status,
            import_jid = project_mirror_data.jid,
            mirror_last_update_at = project_mirror_data.last_update_at,
            mirror_last_successful_update_at = project_mirror_data.last_successful_update_at,
            import_error = project_mirror_data.last_error
          FROM project_mirror_data
          WHERE project_mirror_data.project_id = projects.id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL

        execute <<~SQL
          UPDATE project_mirror_data
          SET status = 'none'
          FROM projects
          WHERE projects.id = project_id
          AND projects.mirror = TRUE
          AND projects.id BETWEEN #{start} AND #{stop}
        SQL
      end
    end
  end
end
