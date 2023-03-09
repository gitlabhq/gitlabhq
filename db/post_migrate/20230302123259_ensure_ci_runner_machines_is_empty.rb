# frozen_string_literal: true

class EnsureCiRunnerMachinesIsEmpty < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_ci)

    # Ensure that the ci_runner_machines table is empty to ensure that new builds
    # don't try to create new join records until we add the missing FK.
    execute('TRUNCATE TABLE ci_runner_machines, p_ci_runner_machine_builds')
  end

  def down
    # no-op
  end
end
