# frozen_string_literal: true

class AddIndexOnCiPipelinesUserIdIdFailureReason < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pipelines_on_user_id_and_id_desc_and_user_not_verified'

  def up
    add_concurrent_index :ci_pipelines, [:user_id, :id], order: { id: :desc }, where: 'failure_reason = 3', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipelines, INDEX_NAME
  end
end
