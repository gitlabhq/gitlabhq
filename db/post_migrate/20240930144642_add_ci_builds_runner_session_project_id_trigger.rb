# frozen_string_literal: true

class AddCiBuildsRunnerSessionProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_builds_runner_session,
      sharding_key: :project_id,
      parent_table: :p_ci_builds,
      parent_sharding_key: :project_id,
      foreign_key: :build_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_builds_runner_session,
      sharding_key: :project_id,
      parent_table: :p_ci_builds,
      parent_sharding_key: :project_id,
      foreign_key: :build_id
    )
  end
end
