# frozen_string_literal: true

class ResetAttentionRequestedMergeRequestsReviewersStateToUnreviewed < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 500

  class MergeRequestReviewer < MigrationRecord
    self.table_name = 'merge_request_reviewers'

    enum state: {
      unreviewed: 0,
      reviewed: 1,
      attention_requested: 2
    }

    include ::EachBatch
  end

  def up
    MergeRequestReviewer
      .where(state: MergeRequestReviewer.states['attention_requested'])
      .each_batch(of: BATCH_SIZE) { |batch| batch.update_all(state: MergeRequestReviewer.states['unreviewed']) }
  end

  def down
    # no op
  end
end
