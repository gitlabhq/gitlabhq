# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to populates the migration_plan column of container_repositories
    # with the current plan of the namespaces that owns the container_repository
    #
    # The plan can be NULL, in which case no UPDATE
    # will be executed.
    class PopulateContainerRepositoryMigrationPlan
      def perform(start_id, end_id)
        (start_id..end_id).each do |id|
          execute(<<~SQL)
            WITH selected_plan AS (
              SELECT "plans"."name"
              FROM "container_repositories"
              INNER JOIN "projects" ON "projects"."id" = "container_repositories"."project_id"
              INNER JOIN "namespaces" ON "namespaces"."id" = "projects"."namespace_id"
              INNER JOIN "gitlab_subscriptions" ON "gitlab_subscriptions"."namespace_id" = "namespaces"."traversal_ids"[1]
              INNER JOIN "plans" ON "plans"."id" = "gitlab_subscriptions"."hosted_plan_id"
              WHERE "container_repositories"."id" = #{id}
            )
            UPDATE container_repositories
            SET migration_plan = selected_plan.name
            FROM selected_plan
            WHERE container_repositories.id = #{id};
          SQL
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def connection
        @connection ||= ApplicationRecord.connection
      end

      def execute(sql)
        connection.execute(sql)
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
