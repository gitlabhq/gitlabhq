# frozen_string_literal: true

class AddProjectIdToCiSecureFileStates < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_secure_file_states, :project_id, :bigint
  end
end
