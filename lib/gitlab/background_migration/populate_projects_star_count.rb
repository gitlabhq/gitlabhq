# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to populates the star counter of projects
    class PopulateProjectsStarCount < BatchedMigrationJob
      MAX_UPDATE_RETRIES = 3

      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          update_with_retry(sub_batch)
        end
      end

      private

      # rubocop:disable Database/RescueQueryCanceled
      # rubocop:disable Database/RescueStatementTimeout
      def update_with_retry(sub_batch)
        update_attempt = 1

        begin
          update_batch(sub_batch)
        rescue ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled => e
          update_attempt += 1

          if update_attempt <= MAX_UPDATE_RETRIES
            sleep(5)
            retry
          end

          raise e
        end
      end
      # rubocop:enable Database/RescueQueryCanceled
      # rubocop:enable Database/RescueStatementTimeout

      def update_batch(sub_batch)
        ::Gitlab::Database.allow_cross_joins_across_databases(url:
            'https://gitlab.com/gitlab-org/gitlab/-/issues/421843') do
          ApplicationRecord.connection.execute <<~SQL
            WITH batched_relation AS MATERIALIZED (#{sub_batch.select(:id).to_sql})
            UPDATE projects
            SET star_count = (
              SELECT COUNT(*)
              FROM users_star_projects
              INNER JOIN users
              ON users_star_projects.user_id = users.id
              WHERE users_star_projects.project_id = batched_relation.id
              AND users.state = 'active'
            )
            FROM batched_relation
            WHERE projects.id = batched_relation.id
          SQL
        end
      end
    end
  end
end
