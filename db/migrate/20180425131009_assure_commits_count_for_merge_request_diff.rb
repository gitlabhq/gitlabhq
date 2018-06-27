class AssureCommitsCountForMergeRequestDiff < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal('AddMergeRequestDiffCommitsCount')

    MergeRequestDiff.where(commits_count: nil).each_batch(of: 50) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::AddMergeRequestDiffCommitsCount.new.perform(*range)
    end
  end

  def down
    # noop
  end
end
