class CleanUpFromMergeRequestDiffsAndCommits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('DeserializeMergeRequestDiffsAndCommits')

    # The literal '--- []\n' value is created by the import process and treated
    # as null by the application, so we can ignore those - even if we were
    # migrating, it wouldn't create any rows.
    literal_prefix = Gitlab::Database.postgresql? ? 'E' : ''
    non_empty = "
      (st_commits IS NOT NULL AND st_commits != #{literal_prefix}'--- []\n')
      OR
      (st_diffs IS NOT NULL AND st_diffs != #{literal_prefix}'--- []\n')
    ".squish

    MergeRequestDiff.where(non_empty).each_batch(of: 500) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::DeserializeMergeRequestDiffsAndCommits.new.perform(*range)
    end
  end

  def down
  end
end
