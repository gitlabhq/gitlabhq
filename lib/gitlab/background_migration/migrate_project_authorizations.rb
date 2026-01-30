# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateProjectAuthorizations < BatchedMigrationJob
      # Iterate over full PK with ASC ordering. This ensures that for duplicate
      # (user_id, project_id) pairs, the row with the smaller access_level is
      # processed first. Combined with ON CONFLICT DO NOTHING, this preserves
      # the minimum access_level even if duplicates are split across batches.
      cursor :user_id, :project_id, :access_level
      operation_name :migrate
      feature_category :user_management

      DEST_TABLE = 'project_authorizations_for_migration'

      def perform
        each_sub_batch do |relation|
          connection.execute(insert_query(relation))
        end
      end

      def insert_query(relation)
        # If there is a conflicting row in `project_authorizations_for_migration`,
        # the write was forwarded by the trigger on `project_authorizations`.
        # ON CONFLICT DO NOTHING because in conflict the existing row was either:
        # * forwarded by the trigger on `project_authorizations` and is hence more
        #   recent
        # * written from a previous batch, then the existing row has a lower
        #   access level due to the ASC ordering
        <<~SQL
          WITH deduplicated AS (
            SELECT
              project_id,
              user_id,
              MIN(access_level)::smallint AS access_level
            FROM (#{relation.to_sql}) AS batch
            GROUP BY project_id, user_id
          )
          INSERT INTO #{DEST_TABLE} (project_id, user_id, access_level)
          SELECT project_id, user_id, access_level
          FROM deduplicated
          ON CONFLICT (project_id, user_id) DO NOTHING
        SQL
      end
    end
  end
end
