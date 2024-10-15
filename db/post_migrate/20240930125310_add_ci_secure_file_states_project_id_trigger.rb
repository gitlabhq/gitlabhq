# frozen_string_literal: true

class AddCiSecureFileStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_secure_file_states,
      sharding_key: :project_id,
      parent_table: :ci_secure_files,
      parent_sharding_key: :project_id,
      foreign_key: :ci_secure_file_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_secure_file_states,
      sharding_key: :project_id,
      parent_table: :ci_secure_files,
      parent_sharding_key: :project_id,
      foreign_key: :ci_secure_file_id
    )
  end
end
