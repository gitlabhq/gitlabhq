# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDiffNotePositionsNamespaceId < BatchedMigrationJob
      operation_name :set_namespace_id_on_diff_note_position_records
      feature_category :code_review_workflow

      TABLE_NAME = :diff_note_positions
      FOREIGN_KEY = :note_id

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(build_update_query(sub_batch))
        end
      end

      private

      def build_update_query(sub_batch)
        <<~SQL
          WITH relation AS MATERIALIZED (
            #{sub_batch.select(:id, FOREIGN_KEY).limit(sub_batch_size).to_sql}
          ), relation_with_namespace_id AS MATERIALIZED (
            #{namespace_relation_subquery}
          )
          #{update_statement}
        SQL
      end

      def namespace_relation_subquery
        <<~SQL
          SELECT "relation".*, "projects"."project_namespace_id" AS namespace_id
          FROM "relation"
          INNER JOIN "notes" ON "notes"."id" = "relation"."#{FOREIGN_KEY}"
          INNER JOIN "projects" ON "projects"."id" = "notes"."project_id"
          LIMIT #{sub_batch_size}
        SQL
      end

      def update_statement
        <<~SQL
          UPDATE "#{TABLE_NAME}"
          SET "namespace_id" = "relation_with_namespace_id"."namespace_id"
          FROM "relation_with_namespace_id"
          WHERE "#{TABLE_NAME}"."id" = "relation_with_namespace_id"."id"
        SQL
      end
    end
  end
end
