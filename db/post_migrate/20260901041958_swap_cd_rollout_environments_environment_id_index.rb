# frozen_string_literal: true

class SwapCdRolloutEnvironmentsEnvironmentIdIndex < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_cd_rollout_environments_on_environment_state_finished_at'
  OLD_INDEX_NAME = 'index_cd_rollout_environments_on_environment_id'

  # Create the replacement before dropping the old index so the
  # environment_id foreign key is never left without an index.
  def up
    add_concurrent_index(
      :cd_rollout_environments,
      [:environment_id, :state, :finished_at, :id],
      order: { finished_at: :DESC, id: :DESC },
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(:cd_rollout_environments, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:cd_rollout_environments, :environment_id, name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name(:cd_rollout_environments, NEW_INDEX_NAME)
  end
end
