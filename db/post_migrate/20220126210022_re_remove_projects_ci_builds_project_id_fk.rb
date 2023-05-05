# frozen_string_literal: true

class ReRemoveProjectsCiBuildsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_builds, :projects, name: "fk_befce0568a")

    with_lock_retries do
      execute('LOCK projects, ci_builds IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_builds, :projects, name: "fk_befce0568a")
    end
  end

  def down
    # no-op, since the FK will be added via rollback by prior-migration
  end
end
