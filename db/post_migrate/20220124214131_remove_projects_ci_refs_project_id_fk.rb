# frozen_string_literal: true

class RemoveProjectsCiRefsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_refs, :projects, name: "fk_rails_4249db8cc3")

    with_lock_retries do
      execute('LOCK projects, ci_refs IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_refs, :projects, name: "fk_rails_4249db8cc3")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_refs, :projects, name: "fk_rails_4249db8cc3", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
