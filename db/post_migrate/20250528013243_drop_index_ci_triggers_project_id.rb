# frozen_string_literal: true

class DropIndexCiTriggersProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :ci_triggers
  COLUMNS = [:project_id]
  INDEX_NAME = :index_ci_triggers_on_project_id

  def up
    remove_concurrent_index_by_name(TABLE_NAME, name: INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
