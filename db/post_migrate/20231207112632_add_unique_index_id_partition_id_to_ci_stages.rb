# frozen_string_literal: true

class AddUniqueIndexIdPartitionIdToCiStages < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  PK_INDEX_NAME = :index_ci_stages_on_id_partition_id_unique

  def up
    add_concurrent_index(TABLE_NAME, %i[id partition_id], unique: true, name: PK_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, PK_INDEX_NAME)
  end
end
