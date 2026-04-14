# frozen_string_literal: true

class AddShardNumberToCiNamespaceMonthlyUsages < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  INDEX_NAME = 'idx_ci_namespace_monthly_usages_namespace_id_date_shard_number'
  OLD_INDEX_NAME = 'index_ci_namespace_monthly_usages_on_namespace_id_and_date'

  def up
    with_lock_retries do
      add_column :ci_namespace_monthly_usages, :shard_number, :integer, default: 1, null: false, if_not_exists: true
    end

    add_concurrent_index :ci_namespace_monthly_usages, [:namespace_id, :date, :shard_number], unique: true,
      name: INDEX_NAME
    remove_concurrent_index_by_name :ci_namespace_monthly_usages, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_namespace_monthly_usages, [:namespace_id, :date], unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :ci_namespace_monthly_usages, INDEX_NAME

    with_lock_retries do
      remove_column :ci_namespace_monthly_usages, :shard_number
    end
  end
end
