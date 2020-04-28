# frozen_string_literal: true

class BackfillEnvironmentIdOnDeploymentMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 400
  DELAY = 1.minute

  disable_ddl_transaction!

  def up
    max_mr_id = DeploymentMergeRequest
      .select(:merge_request_id)
      .distinct
      .order(merge_request_id: :desc)
      .limit(1)
      .pluck(:merge_request_id)
      .first || 0

    last_mr_id = 0
    step = 0

    while last_mr_id < max_mr_id
      stop =
        DeploymentMergeRequest
          .select(:merge_request_id)
          .distinct
          .where('merge_request_id > ?', last_mr_id)
          .order(:merge_request_id)
          .offset(BATCH_SIZE)
          .limit(1)
          .pluck(:merge_request_id)
          .first

      stop ||= max_mr_id

      migrate_in(
        step * DELAY,
        'BackfillEnvironmentIdDeploymentMergeRequests',
        [last_mr_id + 1, stop]
      )

      last_mr_id = stop
      step += 1
    end
  end

  def down
    # no-op

    # this migration is designed to delete duplicated data
  end
end
