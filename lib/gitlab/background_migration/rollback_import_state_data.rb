# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration migrates all the data of import_state
    # back to the projects table for projects that are considered imports or forks
    class RollbackImportStateData
      def perform(start_id, end_id)
        move_attributes_data_to_project(start_id, end_id)
      end

      def move_attributes_data_to_project(start_id, end_id)
        Rails.logger.info("#{self.class.name} - Moving import attributes data to projects table: #{start_id} - #{end_id}")

        if Gitlab::Database.mysql?
          ActiveRecord::Base.connection.execute <<~SQL
            UPDATE projects, project_mirror_data
            SET
              projects.import_status = project_mirror_data.status,
              projects.import_jid = project_mirror_data.jid,
              projects.import_error = project_mirror_data.last_error
            WHERE project_mirror_data.project_id = projects.id
            AND project_mirror_data.id BETWEEN #{start_id} AND #{end_id}
          SQL
        else
          ActiveRecord::Base.connection.execute <<~SQL
            UPDATE projects
            SET
              import_status = project_mirror_data.status,
              import_jid = project_mirror_data.jid,
              import_error = project_mirror_data.last_error
            FROM project_mirror_data
            WHERE project_mirror_data.project_id = projects.id
            AND project_mirror_data.id BETWEEN #{start_id} AND #{end_id}
          SQL
        end
      end
    end
  end
end
