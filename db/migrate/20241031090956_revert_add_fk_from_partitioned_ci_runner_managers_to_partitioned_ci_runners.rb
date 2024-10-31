# frozen_string_literal: true

class RevertAddFkFromPartitionedCiRunnerManagersToPartitionedCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_runner_machines_687967fa8a
  TARGET_TABLE_NAME = :ci_runners_e59bb2812d
  FK_NAME = :fk_rails_3f92913d27

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: FK_NAME, reverse_lock_order: true)
    end
  end

  def down
    # no-op
  end
end
