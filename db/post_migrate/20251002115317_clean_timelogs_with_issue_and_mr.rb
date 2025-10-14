# frozen_string_literal: true

class CleanTimelogsWithIssueAndMr < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.5'

  def up
    batch_scope = ->(model) { model.where('issue_id IS NOT NULL AND merge_request_id IS NOT NULL') }

    each_batch(:timelogs, scope: batch_scope, of: BATCH_SIZE) do |batch|
      # If for any reason records exist in this state, keeping issue as it's used in chart calculations.
      batch.update_all(merge_request_id: nil)
    end
  end

  def down
    # no-op
  end
end
