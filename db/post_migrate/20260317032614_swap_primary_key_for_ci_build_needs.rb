# frozen_string_literal: true

class SwapPrimaryKeyForCiBuildNeeds < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = :ci_build_needs
  PRIMARY_KEY = :ci_build_needs_pkey
  OLD_INDEX_NAME = :ci_build_needs_pkey_no_partitioning
  NEW_INDEX_NAME = :ci_build_needs_pkey_partitioning

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX_NAME)
  end
end
