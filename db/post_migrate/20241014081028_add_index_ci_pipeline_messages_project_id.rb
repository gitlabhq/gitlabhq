# frozen_string_literal: true

class AddIndexCiPipelineMessagesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_messages
  INDEX_NAME = :index_ci_pipeline_messages_on_project_id

  def up
    prepare_async_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end
end
