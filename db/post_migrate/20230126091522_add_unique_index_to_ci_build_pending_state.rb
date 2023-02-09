# frozen_string_literal: true

class AddUniqueIndexToCiBuildPendingState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = :index_ci_build_pending_states_on_partition_id_build_id
  NEW_INDEX_NAME = :unique_index_ci_build_pending_states_on_partition_id_build_id
  TABLE_NAME = :ci_build_pending_states
  COLUMNS = [:partition_id, :build_id]

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, unique: true, name: NEW_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMNS, name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
