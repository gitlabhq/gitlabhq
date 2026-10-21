# frozen_string_literal: true

class DeleteMergeSchedulesWithNullMergeAfter < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.6'

  BATCH_SIZE = 1000

  class MergeSchedule < MigrationRecord
    include EachBatch

    self.table_name = 'merge_request_merge_schedules'
  end

  def up
    MergeSchedule.reset_column_information

    MergeSchedule.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(merge_after: nil).delete_all
    end
  end

  def down
    # no-op: can't know which MRs had an invalid merge schedule attached.
    # Trying to recover them would be pointless anyway since a merge schedule
    # with merge_after set to null is a no-op in itself.
  end
end
