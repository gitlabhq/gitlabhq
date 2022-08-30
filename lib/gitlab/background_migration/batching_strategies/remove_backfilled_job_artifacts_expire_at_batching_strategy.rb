# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for removing backfilled job artifact expire_at.
      # Batches will be scoped to records where either:
      # - expire_at is set to midnight on the 22nd of the month of the local timezone,
      # - record that has file_type = 3 (trace)
      #
      # If no more batches exist in the table, returns nil.
      class RemoveBackfilledJobArtifactsExpireAtBatchingStrategy < PrimaryKeyBatchingStrategy
        EXPIRES_ON_21_22_23_AT_MIDNIGHT_IN_TIMEZONE = <<~SQL
          EXTRACT(day FROM timezone('UTC', expire_at)) IN (21, 22, 23)
          AND EXTRACT(minute FROM timezone('UTC', expire_at)) IN (0, 30, 45)
          AND EXTRACT(second FROM timezone('UTC', expire_at)) = 0
        SQL

        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation.where(EXPIRES_ON_21_22_23_AT_MIDNIGHT_IN_TIMEZONE)
                  .or(relation.where(file_type: 3))
        end
      end
    end
  end
end
