# frozen_string_literal: true

class DropOldUniqueIndexForCiBuildNeeds < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  TABLE_NAME = :ci_build_needs
  INDEX_NAME = :index_ci_build_needs_on_build_id_and_name
  COLUMNS = %i[build_id name]

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME, unique: true)
  end
end
