# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for back-filling project_statistic's container_registry_size.
      # Batches will be scoped to records where the project_ids are migrated
      #
      # If no more batches exist in the table, returns nil.
      class BackfillProjectStatisticsWithContainerRegistrySizeBatchingStrategy < PrimaryKeyBatchingStrategy
        MIGRATION_PHASE_1_ENDED_AT = Date.new(2022, 01, 23).freeze

        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation.where(created_at: MIGRATION_PHASE_1_ENDED_AT..).or(
            relation.where(migration_state: 'import_done')
          ).select(:project_id).distinct
        end
      end
    end
  end
end
