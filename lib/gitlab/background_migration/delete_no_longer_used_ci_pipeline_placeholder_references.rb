# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteNoLongerUsedCiPipelinePlaceholderReferences < BatchedMigrationJob
      operation_name :delete_ci_pipeline_placeholder_references
      feature_category :importers

      PLACEHOLDER_USER_TYPE = 15

      MODEL_USER_REFERENCE_COLUMN_MAPPING = [
        { model: %w[Ci::Bridge Ci::Build GenericCommitStatus], user_reference_column: %w[user_id] },
        { model: %w[ProjectSnippet], user_reference_column: %w[author_id] },
        { model: %w[WorkItem], user_reference_column: %w[author_id updated_by_id closed_by_id] }
      ].freeze

      def perform
        each_sub_batch do |sub_batch|
          delete_placeholder_references_for_batch(sub_batch)
        end
      end

      private

      def delete_placeholder_references_for_batch(sub_batch)
        query = build_or_clauses_query(sub_batch)
        query_with_joins = add_placeholder_user_joins(query)
        query_with_joins.delete_all
      end

      def build_or_clauses_query(sub_batch)
        MODEL_USER_REFERENCE_COLUMN_MAPPING.reduce(sub_batch.none) do |combined_query, condition|
          combined_query.or(sub_batch.where(condition))
        end
      end

      def add_placeholder_user_joins(query)
        query
          .joins(
            'INNER JOIN import_source_users ON ' \
              'import_source_user_placeholder_references.source_user_id = import_source_users.id'
          )
          .joins('INNER JOIN users ON import_source_users.placeholder_user_id = users.id')
          .where(users: { user_type: PLACEHOLDER_USER_TYPE })
      end
    end
  end
end
