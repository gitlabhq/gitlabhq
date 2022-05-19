# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to reset container_repositories that were skipped in the phase 2 registry
    # migration due to too many tags.
    class ResetTooManyTagsSkippedRegistryImports # rubocop:disable Migration/BackgroundMigrationBaseClass
      class ContainerRepository < ::ApplicationRecord # rubocop:disable Style/Documentation
        include EachBatch

        self.table_name = 'container_repositories'

        scope :base_query, -> { where(migration_state: 'import_skipped', migration_skipped_reason: 2) }
      end

      def perform(start_id, end_id)
        ContainerRepository.base_query.where(id: start_id..end_id).each_batch(of: 100) do |sub_batch|
          sub_batch.update_all(
            migration_pre_import_started_at: nil,
            migration_pre_import_done_at: nil,
            migration_import_started_at: nil,
            migration_import_done_at: nil,
            migration_aborted_at: nil,
            migration_skipped_at: nil,
            migration_retries_count: 0,
            migration_skipped_reason: nil,
            migration_state: 'default',
            migration_aborted_in_state: nil
          )
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
