# frozen_string_literal: true

class PrepareIndexApprovalsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approvals_on_project_id'

  def up
    prepare_async_index :approvals, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :approvals, INDEX_NAME
  end
end
