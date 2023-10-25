# frozen_string_literal: true

class AddIndexToStatusCheckResponsesOnIdAndStatus < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_status_check_responses_on_id_and_status'
  disable_ddl_transaction!

  def up
    add_concurrent_index :status_check_responses, [:id, :status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :status_check_responses, name: INDEX_NAME
  end
end
