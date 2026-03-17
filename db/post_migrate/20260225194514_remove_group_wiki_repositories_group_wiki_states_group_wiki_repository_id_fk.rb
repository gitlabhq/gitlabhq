# frozen_string_literal: true

class RemoveGroupWikiRepositoriesGroupWikiStatesGroupWikiRepositoryIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  FOREIGN_KEY_NAME = "fk_rails_832511c9f1"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:group_wiki_repository_states, :group_wiki_repositories,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:group_wiki_repository_states, :group_wiki_repositories,
      name: FOREIGN_KEY_NAME, column: :group_wiki_repository_id,
      target_column: :group_id, on_delete: :cascade)
  end
end
