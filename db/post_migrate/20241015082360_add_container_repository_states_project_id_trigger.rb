# frozen_string_literal: true

class AddContainerRepositoryStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    install_sharding_key_assignment_trigger(
      table: :container_repository_states,
      sharding_key: :project_id,
      parent_table: :container_repositories,
      parent_sharding_key: :project_id,
      foreign_key: :container_repository_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :container_repository_states,
      sharding_key: :project_id,
      parent_table: :container_repositories,
      parent_sharding_key: :project_id,
      foreign_key: :container_repository_id
    )
  end
end
