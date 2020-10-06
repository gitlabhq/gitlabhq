# frozen_string_literal: true

class AddGroupWikiRepositoriesGroupIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :group_wiki_repositories, :namespaces, column: :group_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :group_wiki_repositories, :namespaces, column: :group_id
    end
  end
end
