# frozen_string_literal: true

class ReplaceWorkItemTypeBackfillNextBatchStrategy < Gitlab::Database::Migration[1.0]
  JOB_CLASS_NAME = 'BackfillWorkItemTypeIdForIssues'
  NEW_STRATEGY_CLASS = 'BackfillIssueWorkItemTypeBatchingStrategy'
  OLD_STRATEGY_CLASS = 'PrimaryKeyBatchingStrategy'

  class InlineBatchedMigration < ApplicationRecord
    self.table_name = :batched_background_migrations
  end

  def up
    InlineBatchedMigration.where(job_class_name: JOB_CLASS_NAME)
                          .update_all(batch_class_name: NEW_STRATEGY_CLASS)
  end

  def down
    InlineBatchedMigration.where(job_class_name: JOB_CLASS_NAME)
                          .update_all(batch_class_name: OLD_STRATEGY_CLASS)
  end
end
