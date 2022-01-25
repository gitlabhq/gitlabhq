# frozen_string_literal: true

class RemoveProjectsCiJobTokenProjectScopeLinksSourceProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_job_token_project_scope_links, :projects, name: "fk_rails_4b2ee3290b")

    with_lock_retries do
      execute('LOCK projects, ci_job_token_project_scope_links IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_job_token_project_scope_links, :projects, name: "fk_rails_4b2ee3290b")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_job_token_project_scope_links, :projects, name: "fk_rails_4b2ee3290b", column: :source_project_id, target_column: :id, on_delete: :cascade)
  end
end
