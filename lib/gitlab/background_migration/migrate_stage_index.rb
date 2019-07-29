# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateStageIndex
      def perform(start_id, stop_id)
        migrate_stage_index_sql(start_id.to_i, stop_id.to_i).tap do |sql|
          ActiveRecord::Base.connection.execute(sql)
        end
      end

      private

      def migrate_stage_index_sql(start_id, stop_id)
        <<~SQL
          WITH freqs AS (
            SELECT stage_id, stage_idx, COUNT(*) AS freq FROM ci_builds
              WHERE stage_id BETWEEN #{start_id} AND #{stop_id}
                AND stage_idx IS NOT NULL
              GROUP BY stage_id, stage_idx
          ), indexes AS (
            SELECT DISTINCT stage_id, first_value(stage_idx)
              OVER (PARTITION BY stage_id ORDER BY freq DESC) AS index
              FROM freqs
          )

          UPDATE ci_stages SET position = indexes.index
            FROM indexes WHERE indexes.stage_id = ci_stages.id
              AND ci_stages.position IS NULL;
        SQL
      end
    end
  end
end
