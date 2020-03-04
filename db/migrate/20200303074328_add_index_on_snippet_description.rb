# frozen_string_literal: true

class AddIndexOnSnippetDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_snippets_on_description_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, :description, name: INDEX_NAME, using: :gin, opclass: { description: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :snippets, INDEX_NAME
  end
end
