class RescheduleCommitsCountForMergeRequestDiff < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'AddMergeRequestDiffCommitsCount'.freeze
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 5.minutes.to_i

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    say 'Populating the MergeRequestDiff `commits_count` (reschedule)'

    execute("SET statement_timeout TO '60s'") if Gitlab::Database.postgresql?

    MergeRequestDiff.where(commits_count: nil).each_batch(of: BATCH_SIZE) do |relation, index|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first
      delay = index * DELAY_INTERVAL

      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [start_id, end_id])
    end
  end
end
