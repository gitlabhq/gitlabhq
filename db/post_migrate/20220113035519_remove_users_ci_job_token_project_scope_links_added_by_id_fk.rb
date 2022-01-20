# frozen_string_literal: true

class RemoveUsersCiJobTokenProjectScopeLinksAddedByIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_job_token_project_scope_links, :users, name: "fk_rails_35f7f506ce")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_job_token_project_scope_links, :users, name: "fk_rails_35f7f506ce", column: :added_by_id, target_column: :id, on_delete: :nullify)
  end
end
