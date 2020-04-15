# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will insert record into project_push_rules
    # for each existing push_rule
    class BackfillPushRulesIdInProjects
      # Temporary AR table for push rules
      class ProjectSetting < ActiveRecord::Base
        self.table_name = 'project_settings'
      end

      def perform(start_id, stop_id)
        ProjectSetting.connection.execute(<<~SQL)
          UPDATE project_settings ps1
          SET push_rule_id = pr.id
          FROM project_settings ps2
          INNER JOIN push_rules pr
          ON ps2.project_id = pr.project_id
          WHERE pr.is_sample = false
          AND pr.id BETWEEN #{start_id} AND #{stop_id}
          AND ps1.project_id = ps2.project_id
        SQL
      end
    end
  end
end
