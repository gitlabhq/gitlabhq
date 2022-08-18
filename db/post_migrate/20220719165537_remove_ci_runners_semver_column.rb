# frozen_string_literal: true

class RemoveCiRunnersSemverColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_id_and_semver_cidr'

  def up
    with_lock_retries do
      remove_column :ci_runners, :semver
    end
  end

  def down
    with_lock_retries do
      add_column :ci_runners, :semver, :text, null: true
    end
    add_text_limit :ci_runners, :semver, 16
    add_concurrent_index :ci_runners, 'id, (semver::cidr)', name: INDEX_NAME
  end
end
