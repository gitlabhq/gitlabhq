# frozen_string_literal: true

class AddProjectIdToWikiRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :wiki_repository_states, :project_id, :bigint
  end
end
