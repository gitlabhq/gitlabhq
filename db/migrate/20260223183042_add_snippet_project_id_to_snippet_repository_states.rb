# frozen_string_literal: true

class AddSnippetProjectIdToSnippetRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :snippet_repository_states, :snippet_project_id, :bigint
  end
end
