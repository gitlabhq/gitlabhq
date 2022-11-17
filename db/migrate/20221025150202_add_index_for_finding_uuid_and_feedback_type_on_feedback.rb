# frozen_string_literal: true

class AddIndexForFindingUuidAndFeedbackTypeOnFeedback < Gitlab::Database::Migration[2.0]
  INDEX_NAME = :index_vulnerability_feedback_on_feedback_type_and_finding_uuid

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_feedback, %i[feedback_type finding_uuid], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_feedback, INDEX_NAME
  end
end
