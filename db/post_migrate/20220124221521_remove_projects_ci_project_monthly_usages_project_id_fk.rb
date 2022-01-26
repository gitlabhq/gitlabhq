# frozen_string_literal: true

class RemoveProjectsCiProjectMonthlyUsagesProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_project_monthly_usages, :projects, name: "fk_rails_508bcd4aa6")

    with_lock_retries do
      execute('LOCK projects, ci_project_monthly_usages IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_project_monthly_usages, :projects, name: "fk_rails_508bcd4aa6")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_project_monthly_usages, :projects, name: "fk_rails_508bcd4aa6", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
