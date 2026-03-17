# frozen_string_literal: true

class AddSnippetRepositoryStatesSnippetProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :snippet_repository_states,
      sharding_key: :snippet_project_id,
      parent_table: :snippet_repositories,
      parent_sharding_key: :snippet_project_id,
      foreign_key: :snippet_repository_id,
      parent_table_primary_key: :snippet_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :snippet_repository_states,
      sharding_key: :snippet_project_id,
      parent_table: :snippet_repositories,
      parent_sharding_key: :snippet_project_id,
      foreign_key: :snippet_repository_id,
      parent_table_primary_key: :snippet_id
    )
  end
end
