# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates all the records on the
    # import state table for projects that are considered imports or forks
    class PopulateImportState
      def perform(start_id, end_id)
        move_attributes_data_to_import_state(start_id, end_id)
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      def move_attributes_data_to_import_state(start_id, end_id)
        Rails.logger.info("#{self.class.name} - Moving import attributes data to project mirror data table: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO project_mirror_data (project_id, status, jid, last_update_at, last_successful_update_at, last_error)
          SELECT id, import_status, import_jid, mirror_last_update_at, mirror_last_successful_update_at, import_error
          FROM projects
          WHERE projects.import_status != 'none'
          AND projects.id BETWEEN #{start_id} AND #{end_id}
          AND NOT EXISTS (
            SELECT id
            FROM project_mirror_data
            WHERE project_id = projects.id
          )
        SQL

        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE projects
          SET import_status = 'none'
          WHERE import_status != 'none'
          AND id BETWEEN #{start_id} AND #{end_id}
        SQL
      end
    end
  end
end
