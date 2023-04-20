# frozen_string_literal: true

class TruncatePCiRunnerMachineBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    truncate_tables!('p_ci_runner_machine_builds')
  end

  # no-op
  def down; end
end
