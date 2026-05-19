# frozen_string_literal: true

class AddGroupWikiRepositoryStatesGroupIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :group_wiki_repository_states, :namespaces,
      column: :group_id, target_column: :id,
      on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :group_wiki_repository_states, column: :group_id
    end
  end
end
