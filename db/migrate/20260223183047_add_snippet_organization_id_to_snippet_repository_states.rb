# frozen_string_literal: true

class AddSnippetOrganizationIdToSnippetRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :snippet_repository_states, :snippet_organization_id, :bigint
  end
end
