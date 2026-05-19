# frozen_string_literal: true

class AddGroupWikiRepositoryStatesGroupWikiRepositoryIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :group_wiki_repository_states, :group_wiki_repositories,
      column: :group_wiki_repository_id, target_column: :group_id,
      on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :group_wiki_repository_states, :group_wiki_repositories,
        column: :group_wiki_repository_id, reverse_lock_order: true
    end
  end
end
