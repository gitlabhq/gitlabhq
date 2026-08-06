# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CleanupRepositoryLanguagesLanguageId < BatchedMigrationJob
      operation_name :cleanup_repository_languages_language_id
      feature_category :source_code_management

      # repository_languages has composite PK (project_id, programming_language_id);
      # project_id alone is not unique.
      cursor :project_id, :programming_language_id

      def perform
        each_sub_batch do |sub_batch|
          copy_language_ids(sub_batch)
          delete_unresolved_languages(sub_batch)
        end
      end

      private

      def copy_language_ids(sub_batch)
        connection.execute(<<~SQL)
          WITH sub_batch AS MATERIALIZED (
            #{bounded_sub_batch_sql(sub_batch)}
          ),
          filtered_relation AS MATERIALIZED (
            SELECT
              sub_batch.project_id,
              sub_batch.programming_language_id,
              programming_languages.language_id AS new_language_id
            FROM sub_batch
            INNER JOIN programming_languages
              ON programming_languages.id = sub_batch.programming_language_id
             AND programming_languages.language_id IS NOT NULL
            WHERE sub_batch.language_id IS NULL
            LIMIT #{sub_batch_size}
          )
          UPDATE repository_languages
          SET language_id = filtered_relation.new_language_id
          FROM filtered_relation
          WHERE repository_languages.project_id = filtered_relation.project_id
            AND repository_languages.programming_language_id = filtered_relation.programming_language_id
            AND repository_languages.language_id IS NULL;
        SQL
      end

      def delete_unresolved_languages(sub_batch)
        connection.execute(<<~SQL)
          WITH sub_batch AS MATERIALIZED (
            #{bounded_sub_batch_sql(sub_batch)}
          ),
          filtered_relation AS MATERIALIZED (
            SELECT project_id, programming_language_id
            FROM sub_batch
            WHERE language_id IS NULL
            LIMIT #{sub_batch_size}
          )
          DELETE FROM repository_languages
          USING filtered_relation
          WHERE repository_languages.project_id = filtered_relation.project_id
            AND repository_languages.programming_language_id = filtered_relation.programming_language_id
            AND repository_languages.language_id IS NULL;
        SQL
      end

      def bounded_sub_batch_sql(sub_batch)
        sub_batch.select(:project_id, :programming_language_id, :language_id).limit(sub_batch_size).to_sql
      end
    end
  end
end
