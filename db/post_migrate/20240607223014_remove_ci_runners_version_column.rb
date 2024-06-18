# frozen_string_literal: true

class RemoveCiRunnersVersionColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.1'

  INDEX_NAME = 'index_ci_runners_on_version'

  def up
    with_lock_retries do
      remove_column :ci_runners, :version
    end
  end

  def down
    add_column :ci_runners, :version, :string, if_not_exists: true
    add_concurrent_index :ci_runners, :version, name: INDEX_NAME
  end
end
