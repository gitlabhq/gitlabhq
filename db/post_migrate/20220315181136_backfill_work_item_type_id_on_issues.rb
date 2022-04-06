# frozen_string_literal: true

class BackfillWorkItemTypeIdOnIssues < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillWorkItemTypeIdForIssues'
  BATCH_CLASS_NAME = 'BackfillIssueWorkItemTypeBatchingStrategy'
  BATCH_SIZE = 10_000
  MAX_BATCH_SIZE = 30_000
  SUB_BATCH_SIZE = 100
  INTERVAL = 2.minutes

  class MigrationWorkItemType < ApplicationRecord
    self.table_name = 'work_item_types'

    def self.id_by_type
      where(namespace_id: nil).order(:base_type).pluck(:base_type, :id).to_h
    end
  end

  def up
    # We expect no more than 5 types. Only 3 of them are expected to have associated issues at the moment
    MigrationWorkItemType.id_by_type.each do |base_type, type_id|
      queue_batched_background_migration(
        MIGRATION,
        :issues,
        :id,
        base_type,
        type_id,
        job_interval: INTERVAL,
        batch_size: BATCH_SIZE,
        max_batch_size: MAX_BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE,
        batch_class_name: BATCH_CLASS_NAME
      )
    end
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration.where(job_class_name: MIGRATION).delete_all
  end
end
