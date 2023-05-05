# frozen_string_literal: true

class ReRemoveProjectsCiStagesProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_stages, :projects, name: "fk_2360681d1d")

    with_lock_retries do
      execute('LOCK projects, ci_stages IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_stages, :projects, name: "fk_2360681d1d")
    end
  end

  def down
    # no-op, since the FK will be added via rollback by prior-migration
  end
end
