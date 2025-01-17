# frozen_string_literal: true

class SyncIndexesForCiPipelineMessagesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_messages
  INDEX_NAME = :index_ci_pipeline_messages_on_project_id

  def up
    add_concurrent_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
