# frozen_string_literal: true

class AddSnippetProjectIdToSnippetStatistics < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :snippet_statistics, :snippet_project_id, :bigint
  end
end
