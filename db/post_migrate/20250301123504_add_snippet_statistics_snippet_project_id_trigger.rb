# frozen_string_literal: true

class AddSnippetStatisticsSnippetProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :snippet_statistics,
      sharding_key: :snippet_project_id,
      parent_table: :snippets,
      parent_sharding_key: :project_id,
      foreign_key: :snippet_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :snippet_statistics,
      sharding_key: :snippet_project_id,
      parent_table: :snippets,
      parent_sharding_key: :project_id,
      foreign_key: :snippet_id
    )
  end
end
