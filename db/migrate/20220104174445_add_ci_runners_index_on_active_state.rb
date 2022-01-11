# frozen_string_literal: true

class AddCiRunnersIndexOnActiveState < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_active'

  def up
    add_concurrent_index :ci_runners, [:active, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
