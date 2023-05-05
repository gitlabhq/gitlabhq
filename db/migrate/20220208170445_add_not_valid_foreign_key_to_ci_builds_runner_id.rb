# frozen_string_literal: true

class AddNotValidForeignKeyToCiBuildsRunnerId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_builds, :ci_runners, column: :runner_id, on_delete: :nullify, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ci_builds, column: :runner_id
    end
  end
end
