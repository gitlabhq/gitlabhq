# frozen_string_literal: true

class AddTmpIndexToSupportLeakyRegexCleanup < Gitlab::Database::Migration[1.0]
  INDEX_NAME = "tmp_index_merge_requests_draft_and_status_leaky_regex"
  LEAKY_REGEXP_STR = "^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP"
  CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :id,
      where: "draft = true AND state_id = 1 AND ((title)::text ~* '#{LEAKY_REGEXP_STR}'::text) AND ((title)::text !~* '#{CORRECTED_REGEXP_STR}'::text)",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
