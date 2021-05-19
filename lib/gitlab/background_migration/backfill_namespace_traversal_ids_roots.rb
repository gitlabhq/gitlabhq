# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to set namespaces.traversal_ids in sub-batches, of all namespaces
    # without a parent and not already set.
    # rubocop:disable Style/Documentation
    class BackfillNamespaceTraversalIdsRoots
      class Namespace < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'namespaces'

        scope :base_query, -> { where(parent_id: nil) }
      end

      PAUSE_SECONDS = 0.1

      def perform(start_id, end_id, sub_batch_size)
        ranged_query = Namespace.base_query
          .where(id: start_id..end_id)
          .where("traversal_ids = '{}'")

        ranged_query.each_batch(of: sub_batch_size) do |sub_batch|
          first, last = sub_batch.pluck(Arel.sql('min(id), max(id)')).first

          # The query need to be reconstructed because .each_batch modifies the default scope
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330510
          Namespace.unscoped
                   .base_query
                   .where(id: first..last)
                   .where("traversal_ids = '{}'")
                   .update_all('traversal_ids = ARRAY[id]')

          sleep PAUSE_SECONDS
        end

        mark_job_as_succeeded(start_id, end_id, sub_batch_size)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'BackfillNamespaceTraversalIdsRoots',
          arguments
        )
      end
    end
  end
end
