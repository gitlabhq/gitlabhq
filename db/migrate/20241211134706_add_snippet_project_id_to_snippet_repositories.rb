# frozen_string_literal: true

class AddSnippetProjectIdToSnippetRepositories < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :snippet_repositories, :snippet_project_id, :bigint
  end
end
