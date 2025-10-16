# frozen_string_literal: true

class AddLastQueriedAtColumnToCodeRepositories < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_p_ai_active_context_code_repositories_on_last_queried_at'

  def up
    with_lock_retries do
      add_column :p_ai_active_context_code_repositories, :last_queried_at, :datetime_with_timezone, if_not_exists: true
    end

    add_concurrent_partitioned_index :p_ai_active_context_code_repositories, :last_queried_at, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_column :p_ai_active_context_code_repositories, :last_queried_at, if_exists: true
    end
  end
end
