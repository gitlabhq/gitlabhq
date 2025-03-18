# frozen_string_literal: true

class AddSnippetOrganizationIdToSnippetStatistics < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :snippet_statistics, :snippet_organization_id, :bigint
  end
end
