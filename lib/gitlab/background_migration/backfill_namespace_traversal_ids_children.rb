# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to set namespaces.traversal_ids in sub-batches, of all namespaces with
    # a parent and not already set.
    # rubocop:disable Style/Documentation
    class BackfillNamespaceTraversalIdsChildren
      class Namespace < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'namespaces'

        scope :base_query, -> { where.not(parent_id: nil) }
      end

      PAUSE_SECONDS = 0.1

      def perform(start_id, end_id, sub_batch_size)
        batch_query = Namespace.base_query.where(id: start_id..end_id)
        batch_query.each_batch(of: sub_batch_size) do |sub_batch|
          first, last = sub_batch.pluck(Arel.sql('min(id), max(id)')).first
          ranged_query = Namespace.unscoped.base_query.where(id: first..last)

          update_sql = <<~SQL
            UPDATE namespaces
            SET traversal_ids = calculated_ids.traversal_ids
            FROM #{calculated_traversal_ids(ranged_query)} calculated_ids
            WHERE namespaces.id = calculated_ids.id
              AND namespaces.traversal_ids = '{}'
          SQL
          ActiveRecord::Base.connection.execute(update_sql)

          sleep PAUSE_SECONDS
        end

        # We have to add all arguments when marking a job as succeeded as they
        #  are all used to track the job by `queue_background_migration_jobs_by_range_at_intervals`
        mark_job_as_succeeded(start_id, end_id, sub_batch_size)
      end

      private

      # Calculate the ancestor path for a given set of namespaces.
      def calculated_traversal_ids(batch)
        <<~SQL
          (
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
            SELECT flat_hierarchy.source_id as id,
                   array_agg(flat_hierarchy.namespace_id ORDER BY flat_hierarchy.height DESC) as traversal_ids
            FROM (SELECT * FROM cte FOR UPDATE) flat_hierarchy
            GROUP BY flat_hierarchy.source_id
          )
        SQL
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'BackfillNamespaceTraversalIdsChildren',
          arguments
        )
      end
    end
  end
end
