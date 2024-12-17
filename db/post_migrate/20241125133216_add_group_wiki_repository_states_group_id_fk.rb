# frozen_string_literal: true

class AddGroupWikiRepositoryStatesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :group_wiki_repository_states, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :group_wiki_repository_states, column: :group_id
    end
  end
end
