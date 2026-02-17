# frozen_string_literal: true

class AddNotNullConstraintToCiSecureFileStatesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  def up
    add_not_null_constraint :ci_secure_file_states, :project_id
  end

  def down
    remove_not_null_constraint :ci_secure_file_states, :project_id
  end
end
