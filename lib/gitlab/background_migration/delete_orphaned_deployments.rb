# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for deleting orphaned deployments.
    class DeleteOrphanedDeployments
      include Database::MigrationHelpers

      def perform(start_id, end_id)
        orphaned_deployments
          .where(id: start_id..end_id)
          .delete_all

        mark_job_as_succeeded(start_id, end_id)
      end

      def orphaned_deployments
        define_batchable_model('deployments')
          .where('NOT EXISTS (SELECT 1 FROM environments WHERE deployments.environment_id = environments.id)')
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
