# frozen_string_literal: true

class AddUuidToCiRunners < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '19.2'

  INDEX_NAME = 'index_ci_runners_on_uuid'

  def up
    with_lock_retries do
      add_column :ci_runners, :uuid, :uuid, null: true, if_not_exists: true
    end

    add_concurrent_partitioned_index :ci_runners, [:uuid, :runner_type], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :ci_runners, INDEX_NAME
    with_lock_retries do
      remove_column :ci_runners, :uuid, if_exists: true
    end
  end
end
