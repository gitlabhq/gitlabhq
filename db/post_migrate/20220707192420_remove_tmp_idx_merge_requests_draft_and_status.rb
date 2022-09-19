# frozen_string_literal: true

class RemoveTmpIdxMergeRequestsDraftAndStatus < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_merge_requests_draft_and_status"
  CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

  def up
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, :id,
      where: "draft = false AND state_id = 1 AND ((title)::text ~* '#{CORRECTED_REGEXP_STR}'::text)",
      name: INDEX_NAME
  end
end
