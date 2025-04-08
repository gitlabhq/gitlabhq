# frozen_string_literal: true

class AddTerraformStateVersionStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :terraform_state_version_states,
      sharding_key: :project_id,
      parent_table: :terraform_state_versions,
      parent_sharding_key: :project_id,
      foreign_key: :terraform_state_version_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :terraform_state_version_states,
      sharding_key: :project_id,
      parent_table: :terraform_state_versions,
      parent_sharding_key: :project_id,
      foreign_key: :terraform_state_version_id
    )
  end
end
