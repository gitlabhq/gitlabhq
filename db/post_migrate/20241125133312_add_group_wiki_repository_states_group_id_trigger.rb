# frozen_string_literal: true

class AddGroupWikiRepositoryStatesGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    install_sharding_key_assignment_trigger(
      table: :group_wiki_repository_states,
      sharding_key: :group_id,
      parent_table: :group_wiki_repositories,
      parent_table_primary_key: :group_id,
      parent_sharding_key: :group_id,
      foreign_key: :group_wiki_repository_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :group_wiki_repository_states,
      sharding_key: :group_id,
      parent_table: :group_wiki_repositories,
      parent_table_primary_key: :group_id,
      parent_sharding_key: :group_id,
      foreign_key: :group_wiki_repository_id
    )
  end
end
