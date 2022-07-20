# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for back-filling issue's work_item_type_id for a single issue type.
      # Batches will be scoped to records where the foreign key is NULL and only of a given issue type
      #
      # If no more batches exist in the table, returns nil.
      class BackfillIssueWorkItemTypeBatchingStrategy < PrimaryKeyBatchingStrategy
        def apply_additional_filters(relation, job_arguments:, job_class: nil)
          issue_type = job_arguments.first

          relation.where(issue_type: issue_type)
        end
      end
    end
  end
end
