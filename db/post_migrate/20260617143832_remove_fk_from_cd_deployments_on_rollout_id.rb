# frozen_string_literal: true

class RemoveFkFromCdDeploymentsOnRolloutId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_deployments
  FK_NAME = :fk_828c4990f7

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :cd_rollouts, column: :rollout_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:cd_rollouts)

    add_concurrent_foreign_key TABLE_NAME, :cd_rollouts,
      column: :rollout_id, on_delete: :cascade, name: FK_NAME
  end
end
