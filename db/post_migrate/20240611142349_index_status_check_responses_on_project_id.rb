# frozen_string_literal: true

class IndexStatusCheckResponsesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_status_check_responses_on_project_id'

  def up
    add_concurrent_index :status_check_responses, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :status_check_responses, INDEX_NAME
  end
end
