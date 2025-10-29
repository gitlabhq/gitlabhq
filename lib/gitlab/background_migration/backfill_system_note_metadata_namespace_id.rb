# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSystemNoteMetadataNamespaceId < BatchedMigrationJob
      operation_name :set_namespace_id_on_system_note_metadata_records
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (
                #{sub_batch.select(:id, :note_id).limit(sub_batch_size).to_sql}
              ), relation_with_namespace_id AS MATERIALIZED (
                SELECT "relation".*, COALESCE("projects"."project_namespace_id", "notes"."namespace_id") AS namespace_id
                FROM "relation" INNER JOIN "notes" ON "notes"."id" = "relation"."note_id"
                LEFT JOIN "projects" ON "projects"."id" = "notes"."project_id"
                LIMIT #{sub_batch_size}
              )
              UPDATE "system_note_metadata"
              SET "namespace_id" = "relation_with_namespace_id"."namespace_id"
              FROM "relation_with_namespace_id"
              WHERE "system_note_metadata"."id" = "relation_with_namespace_id"."id"
            SQL
          )
        end
      end
    end
  end
end
