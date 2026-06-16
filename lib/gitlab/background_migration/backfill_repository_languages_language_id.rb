# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRepositoryLanguagesLanguageId < BatchedMigrationJob
      operation_name :backfill_repository_languages_language_id
      feature_category :source_code_management
      # repository_languages has a composite primary key (project_id, programming_language_id).
      # project_id alone is not unique, so the composite cursor is required for correct batching.
      cursor :project_id, :programming_language_id

      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            WITH batched_relation AS MATERIALIZED (
              SELECT rl.project_id, rl.programming_language_id, pl.language_id AS new_language_id
              FROM (#{relation.where(language_id: nil).select(:project_id, :programming_language_id).to_sql}) rl
              INNER JOIN programming_languages pl
                ON pl.id = rl.programming_language_id
               AND pl.language_id IS NOT NULL
            )
            UPDATE repository_languages
            SET language_id = batched_relation.new_language_id
            FROM batched_relation
            WHERE repository_languages.project_id = batched_relation.project_id
              AND repository_languages.programming_language_id = batched_relation.programming_language_id;
          SQL
        end
      end
    end
  end
end
