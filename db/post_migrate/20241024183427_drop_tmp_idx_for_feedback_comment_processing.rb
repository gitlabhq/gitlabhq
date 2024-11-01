# frozen_string_literal: true

class DropTmpIdxForFeedbackCommentProcessing < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = 'vulnerability_feedback'
  INDEX_NAME = 'tmp_idx_for_feedback_comment_processing'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:id], name: INDEX_NAME, where: 'char_length(comment) > 50000'
  end
end
