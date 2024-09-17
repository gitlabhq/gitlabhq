# frozen_string_literal: true

class DropOldUniqueIndexForCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  COLUMN_NAMES = [:project_id, :iid]
  INDEX_NAME = :index_ci_pipelines_on_project_id_and_iid
  WHERE_CLAUSE = 'iid IS NOT NULL'

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME, COLUMN_NAMES,
      unique: true, name: INDEX_NAME, where: WHERE_CLAUSE
    )
  end
end
