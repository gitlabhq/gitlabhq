# frozen_string_literal: true

class TmpIndexForDeleteIssueMergeRequestTaggingsRecords < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_taggings_on_id_where_taggable_type_issue_mr'
  INDEX_CONDITION = "taggable_type IN ('Issue', 'MergeRequest')"

  def up
    add_concurrent_index :taggings, :id, where: INDEX_CONDITION, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end
end
