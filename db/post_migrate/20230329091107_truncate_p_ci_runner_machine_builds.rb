# frozen_string_literal: true

class TruncatePCiRunnerMachineBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_ci)

    execute('TRUNCATE TABLE p_ci_runner_machine_builds')
  end

  # no-op
  def down; end
end
