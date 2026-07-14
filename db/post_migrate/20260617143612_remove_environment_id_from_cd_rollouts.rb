# frozen_string_literal: true

class RemoveEnvironmentIdFromCdRollouts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_rollouts

  def up
    with_lock_retries do
      remove_column TABLE_NAME, :environment_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :environment_id, :bigint unless column_exists?(TABLE_NAME, :environment_id)
    end

    add_concurrent_index TABLE_NAME, :environment_id, name: :index_cd_rollouts_on_environment_id
  end
end
