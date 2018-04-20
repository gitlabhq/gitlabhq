# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateStageIndex
      module Migratable
        class Stage < ActiveRecord::Base
          self.table_name = 'ci_stages'
        end
      end

      def perform(start_id, stop_id)
        sql = <<~SQL
          UPDATE ci_stages
            SET index =
              (SELECT stage_idx FROM ci_builds
                WHERE ci_builds.stage_id = ci_stages.id
                GROUP BY ci_builds.stage_idx ORDER BY COUNT(*) DESC LIMIT 1)
          WHERE ci_stages.id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
            AND ci_stages.index IS NULL
        SQL

        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
