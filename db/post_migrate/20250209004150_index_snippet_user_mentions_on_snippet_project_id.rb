# frozen_string_literal: true

class IndexSnippetUserMentionsOnSnippetProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_snippet_user_mentions_on_snippet_project_id'

  def up
    add_concurrent_index :snippet_user_mentions, :snippet_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_user_mentions, INDEX_NAME
  end
end
