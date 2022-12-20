# frozen_string_literal: true

class AddSupportingIndexForVulnerabilitiesFeedbackCommentProccessing < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "tmp_idx_for_feedback_comment_processing"
  WHERE_CLAUSE = "char_length(comment) > 50000"

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :vulnerability_feedback,
      :id,
      where: WHERE_CLAUSE,
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :vulnerability_feedback,
      INDEX_NAME
    )
  end
end
