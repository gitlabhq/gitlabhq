# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSlackIntegrationsScopesShardingKey < BatchedMigrationJob
      operation_name :set_sharding_key
      feature_category :integrations

      def perform
        each_sub_batch do |sub_batch|
          update_batch(sub_batch)
        end
      end

      private

      def update_batch(sub_batch) # rubocop:disable Metrics/MethodLength -- Long SQL query
        connection.execute(<<~SQL)
          WITH relation AS MATERIALIZED (
            #{sub_batch.select(:id, :slack_integration_id, :slack_api_scope_id).limit(sub_batch_size).to_sql}
          ), required_scopes AS MATERIALIZED (
            SELECT "relation"."id",
              "integrations"."project_id",
              "integrations"."group_id",
              "integrations"."organization_id",
              COALESCE(
                "integrations"."organization_id",
                "namespaces"."organization_id",
                "projects"."organization_id"
              ) AS "computed_organization_id",
              "slack_api_scopes"."name"
            FROM "relation"
            JOIN "slack_integrations" ON "slack_integrations"."id" = "relation"."slack_integration_id"
            JOIN "integrations" ON "integrations"."id" = "slack_integrations"."integration_id"
            LEFT JOIN "namespaces" ON "namespaces"."id" = "integrations"."group_id"
            LEFT JOIN "projects" ON "projects"."id" = "integrations"."project_id"
            JOIN "slack_api_scopes" ON "slack_api_scopes"."id" = "relation"."slack_api_scope_id"
          ), upserted_api_scopes AS MATERIALIZED (
            INSERT INTO "slack_api_scopes" ("organization_id", "name")
            SELECT DISTINCT ON ("computed_organization_id", "name") "computed_organization_id", "name"
            FROM "required_scopes"
            ON CONFLICT ("organization_id", "name")
              DO UPDATE SET "name" = EXCLUDED."name"
            RETURNING *
          )
          UPDATE "slack_integrations_scopes"
          SET "project_id" = "required_scopes"."project_id",
            "group_id" = "required_scopes"."group_id",
            "organization_id" = "required_scopes"."organization_id",
            "slack_api_scope_id" = "upserted_api_scopes"."id"
          FROM "required_scopes"
          JOIN "upserted_api_scopes"
            ON "upserted_api_scopes"."organization_id" = "required_scopes"."computed_organization_id"
            AND "upserted_api_scopes"."name" = "required_scopes"."name"
          WHERE "slack_integrations_scopes"."id" = "required_scopes"."id"
        SQL
      end
    end
  end
end
