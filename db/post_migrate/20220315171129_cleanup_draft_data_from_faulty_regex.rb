# frozen_string_literal: true

class CleanupDraftDataFromFaultyRegex < Gitlab::Database::Migration[1.0]
  MIGRATION       = 'CleanupDraftDataFromFaultyRegex'
  DELAY_INTERVAL  = 5.minutes
  BATCH_SIZE      = 20

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    LEAKY_REGEXP_STR     = "^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP"
    CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

    self.table_name = 'merge_requests'

    include ::EachBatch

    def self.eligible
      where(state_id: 1)
        .where(draft: true)
        .where("title ~* ?", LEAKY_REGEXP_STR)
        .where("title !~* ?", CORRECTED_REGEXP_STR)
    end
  end

  def up
    return unless Gitlab.com?

    queue_background_migration_jobs_by_range_at_intervals(
      MergeRequest.eligible,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # noop
    #
  end
end
