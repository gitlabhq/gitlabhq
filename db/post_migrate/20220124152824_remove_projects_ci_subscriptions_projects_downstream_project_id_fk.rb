# frozen_string_literal: true

class RemoveProjectsCiSubscriptionsProjectsDownstreamProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_subscriptions_projects, :projects, name: "fk_rails_0818751483")

    with_lock_retries do
      execute('LOCK projects, ci_subscriptions_projects IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_subscriptions_projects, :projects, name: "fk_rails_0818751483")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_subscriptions_projects, :projects, name: "fk_rails_0818751483", column: :downstream_project_id, target_column: :id, on_delete: :cascade)
  end
end
