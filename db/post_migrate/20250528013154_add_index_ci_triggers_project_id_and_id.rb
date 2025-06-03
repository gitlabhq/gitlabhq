# frozen_string_literal: true

class AddIndexCiTriggersProjectIdAndId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :ci_triggers
  COLUMNS = [:project_id, :id]
  INDEX_NAME = :index_ci_triggers_on_project_id_and_id

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, name: INDEX_NAME)
  end
end
