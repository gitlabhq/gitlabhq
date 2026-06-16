# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserTypeForGhostUserMigrations < BatchedMigrationJob
      operation_name :backfill_user_type_for_ghost_user_migrations
      feature_category :user_profile

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              UPDATE ghost_user_migrations
              SET user_type=users.user_type
              FROM
                users
              WHERE
                ghost_user_migrations.id IN (#{sub_batch.select(:id).limit(sub_batch_size).to_sql})
                AND ghost_user_migrations.user_type IS NULL
                AND ghost_user_migrations.user_id=users.id
            SQL
          )
        end
      end
    end
  end
end
