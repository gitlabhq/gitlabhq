# frozen_string_literal: true

class AddProjectIdToContainerRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :container_repository_states, :project_id, :bigint
  end
end
