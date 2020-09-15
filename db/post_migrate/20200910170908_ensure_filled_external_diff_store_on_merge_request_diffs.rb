# frozen_string_literal: true

class EnsureFilledExternalDiffStoreOnMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BACKGROUND_MIGRATION_CLASS = 'SetNullExternalDiffStoreToLocalValue'
  BATCH_SIZE = 5_000
  LOCAL_STORE = 1 # equal to ObjectStorage::Store::LOCAL
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal(BACKGROUND_MIGRATION_CLASS)

    # Do a manual update in case we lost BG jobs. The expected record count should be 0 or very low.
    MergeRequestDiff.where(external_diff_store: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      batch.update_all(external_diff_store: LOCAL_STORE)
    end
  end

  def down
    # no-op
  end
end
