# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to create ci_namespace_mirrors entries in batches
    class BackfillCiNamespaceMirrors
      class Namespace < ActiveRecord::Base # rubocop:disable Style/Documentation
        include ::EachBatch

        self.table_name = 'namespaces'
        self.inheritance_column = nil

        scope :base_query, -> do
          select(:id, :parent_id)
        end
      end

      PAUSE_SECONDS = 0.1
      SUB_BATCH_SIZE = 500

      def perform(start_id, end_id)
        batch_query = Namespace.base_query.where(id: start_id..end_id)
        batch_query.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('MIN(id), MAX(id)'))
          ranged_query = Namespace.unscoped.base_query.where(id: first..last)

          update_sql = <<~SQL
            INSERT INTO ci_namespace_mirrors (namespace_id, traversal_ids)
            #{insert_values(ranged_query)}
            ON CONFLICT (namespace_id) DO NOTHING
          SQL
          # We do nothing on conflict because we consider they were already filled.

          Namespace.connection.execute(update_sql)

          sleep PAUSE_SECONDS
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def insert_values(batch)
        calculated_traversal_ids(
          batch.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/336433')
        )
      end

      # Copied from lib/gitlab/background_migration/backfill_namespace_traversal_ids_children.rb
      def calculated_traversal_ids(batch)
        <<~SQL
          WITH RECURSIVE cte(source_id, namespace_id, parent_id, height) AS (
            (
              SELECT batch.id, batch.id, batch.parent_id, 1
              FROM (#{batch.to_sql}) AS batch
            )
            UNION ALL
            (
              SELECT cte.source_id, n.id, n.parent_id, cte.height+1
              FROM namespaces n, cte
              WHERE n.id = cte.parent_id
            )
          )
          SELECT flat_hierarchy.source_id as namespace_id,
                 array_agg(flat_hierarchy.namespace_id ORDER BY flat_hierarchy.height DESC) as traversal_ids
          FROM (SELECT * FROM cte FOR UPDATE) flat_hierarchy
          GROUP BY flat_hierarchy.source_id
        SQL
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('BackfillCiNamespaceMirrors', arguments)
      end
    end
  end
end
