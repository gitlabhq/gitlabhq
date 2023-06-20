# frozen_string_literal: true

class RemoveFkOnProjectIdOnProjectWikiRepositoryStates < Gitlab::Database::Migration[2.1]
  SOURCE_TABLE_NAME = :project_wiki_repository_states
  TARGET_TABLE_NAME = :projects
  FK_NAME = :fk_rails_9647227ce1

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: :project_id, name: FK_NAME, on_delete: :cascade)
  end
end
