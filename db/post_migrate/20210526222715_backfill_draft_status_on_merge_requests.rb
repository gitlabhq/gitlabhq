# frozen_string_literal: true

class BackfillDraftStatusOnMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = "tmp_index_merge_requests_draft_and_status"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :id,
      where: "draft = false AND state_id = 1 AND ((title)::text ~* '^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP'::text)",
      name: INDEX_NAME

    update_column_in_batches(:merge_requests, :draft, true, batch_size: 100) do |table, query|
      query
        .where(table[:state_id].eq(1))
        .where(table[:draft].eq(false))
        .where(table[:title].matches_regexp('^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP', false))
    end

    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
