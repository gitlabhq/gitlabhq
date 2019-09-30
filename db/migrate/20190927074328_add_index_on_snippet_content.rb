# frozen_string_literal: true

class AddIndexOnSnippetContent < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_snippets_on_content_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, :content, name: INDEX_NAME, using: :gin, opclass: { content: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name(:snippets, INDEX_NAME)
  end
end
