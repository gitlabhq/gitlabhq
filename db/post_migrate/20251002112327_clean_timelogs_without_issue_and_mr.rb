# frozen_string_literal: true

class CleanTimelogsWithoutIssueAndMr < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.5'

  def up
    batch_scope = ->(model) { model.where('issue_id IS NULL AND merge_request_id IS NULL') }

    each_batch(:timelogs, scope: batch_scope, of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op
  end
end
