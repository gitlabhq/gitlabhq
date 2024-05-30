# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fills the `issues.namespace_id` by setting it to corresponding project.project_namespace_id
    class BackfillProjectNamespaceOnIssues < BatchedMigrationJob
      MAX_UPDATE_RETRIES = 3

      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch(
          batching_scope: ->(relation) {
            relation.joins("INNER JOIN projects ON projects.id = issues.project_id")
              .select("issues.id AS issue_id, projects.project_namespace_id").where(issues: { namespace_id: nil })
          }
        ) do |sub_batch|
          # updating issues table results in failed batches quite a bit,
          # to prevent that as much as possible we try to update the same sub-batch up to 3 times.
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
        connection.execute <<~SQL
            UPDATE issues
            SET namespace_id = projects.project_namespace_id
            FROM (#{sub_batch.to_sql}) AS projects(issue_id, project_namespace_id)
            WHERE issues.id = issue_id
        SQL
      end
    end
  end
end
