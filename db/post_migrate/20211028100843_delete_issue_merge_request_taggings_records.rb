# frozen_string_literal: true

class DeleteIssueMergeRequestTaggingsRecords < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_taggings_on_id_where_taggable_type_issue_mr'

  BATCH_SIZE = 3_000
  TAGGABLE_TYPES = %w(Issue MergeRequest)

  class Tagging < ActiveRecord::Base
    self.table_name = "taggings"
  end

  def up
    sleep 2 while Tagging.where(taggable_type: TAGGABLE_TYPES).limit(BATCH_SIZE).delete_all > 0

    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end

  def down
  end
end
