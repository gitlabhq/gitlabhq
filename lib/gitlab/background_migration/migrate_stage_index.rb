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
        if Gitlab::Database.postgresql?
          sql = <<~SQL
            WITH freqs AS (
              SELECT stage_id, stage_idx, COUNT(*) AS freq FROM ci_builds
                WHERE stage_id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
                  AND stage_idx IS NOT NULL
                GROUP BY stage_id, stage_idx
            ), indexes AS (
              SELECT DISTINCT stage_id, last_value(stage_idx)
                OVER (PARTITION BY stage_id ORDER BY freq ASC) AS index
                FROM freqs
            )

            UPDATE ci_stages SET index = indexes.index
              FROM indexes WHERE indexes.stage_id = ci_stages.id
                AND ci_stages.index IS NULL;
          SQL
        else
          sql = <<~SQL
            UPDATE ci_stages
              SET index =
                (SELECT stage_idx FROM ci_builds
                  WHERE ci_builds.stage_id = ci_stages.id
                  GROUP BY ci_builds.stage_idx ORDER BY COUNT(*) DESC LIMIT 1)
            WHERE ci_stages.id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
              AND ci_stages.index IS NULL
          SQL
        end

        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
