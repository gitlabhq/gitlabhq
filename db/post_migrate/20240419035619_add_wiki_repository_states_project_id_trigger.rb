# frozen_string_literal: true

class AddWikiRepositoryStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :wiki_repository_states,
      sharding_key: :project_id,
      parent_table: :project_wiki_repositories,
      parent_sharding_key: :project_id,
      foreign_key: :project_wiki_repository_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :wiki_repository_states,
      sharding_key: :project_id,
      parent_table: :project_wiki_repositories,
      parent_sharding_key: :project_id,
      foreign_key: :project_wiki_repository_id
    )
  end
end
