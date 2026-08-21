# frozen_string_literal: true

class RemoveTmpBigintFkForDeploymentsPhaseTwoRetryTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.3'

  # The default timings top out at a 2 second lock_timeout, which was not enough
  # to acquire ACCESS EXCLUSIVE on both projects and deployments. This escalates
  # the lock_timeout and waits a minute between attempts.
  TIMING_CONFIGURATION = ([
    [1.second, 1.minute],
    [2.seconds, 1.minute],
    [3.seconds, 1.minute],
    [5.seconds, 1.minute],
    [7.seconds, 1.minute]
  ] * 3).freeze

  def up
    return unless can_execute_on?(:deployments)

    with_lock_retries(timing_configuration: TIMING_CONFIGURATION, raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        :deployments,
        :projects,
        name: :fk_b9a3851b82_tmp,
        reverse_lock_order: true
      )
    end
  end

  # Recreated as NOT VALID, matching how AddBigintFkForDeploymentsPhaseTwo
  # first added it.
  def down
    return unless can_execute_on?(:deployments)
    return unless column_exists?(:deployments, :project_id_convert_to_bigint)

    add_concurrent_foreign_key(
      :deployments,
      :projects,
      column: :project_id_convert_to_bigint,
      target_column: :id,
      name: :fk_b9a3851b82_tmp,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end
end
