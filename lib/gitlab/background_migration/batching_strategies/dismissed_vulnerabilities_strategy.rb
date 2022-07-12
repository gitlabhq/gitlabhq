# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for setting state in vulnerabilitites table.
      # Batches will be scoped to records where the dismissed_at is set.
      #
      # If no more batches exist in the table, returns nil.
      class DismissedVulnerabilitiesStrategy < PrimaryKeyBatchingStrategy
        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation.where.not(dismissed_at: nil)
        end
      end
    end
  end
end
