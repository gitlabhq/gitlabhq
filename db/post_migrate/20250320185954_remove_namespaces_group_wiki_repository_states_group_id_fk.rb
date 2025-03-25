# frozen_string_literal: true

class RemoveNamespacesGroupWikiRepositoryStatesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_621768bf3d"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:group_wiki_repository_states, :namespaces,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:group_wiki_repository_states, :namespaces,
      name: FOREIGN_KEY_NAME, column: :group_id,
      target_column: :id, on_delete: :cascade)
  end
end
