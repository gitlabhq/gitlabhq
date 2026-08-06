# frozen_string_literal: true

class AddRunnerMachineIdToCiPendingBuilds < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    add_column :ci_pending_builds, :runner_machine_id, :bigint, if_not_exists: true
  end

  def down
    remove_column :ci_pending_builds, :runner_machine_id, if_exists: true
  end
end
