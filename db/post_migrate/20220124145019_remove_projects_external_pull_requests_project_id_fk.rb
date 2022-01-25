# frozen_string_literal: true

class RemoveProjectsExternalPullRequestsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:external_pull_requests, :projects, name: "fk_rails_bcae9b5c7b")

    with_lock_retries do
      execute('LOCK projects, external_pull_requests IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:external_pull_requests, :projects, name: "fk_rails_bcae9b5c7b")
    end
  end

  def down
    add_concurrent_foreign_key(:external_pull_requests, :projects, name: "fk_rails_bcae9b5c7b", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
