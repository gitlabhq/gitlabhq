# frozen_string_literal: true

class AddIndexOnSnippetTypeAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, [:id, :type]
  end

  def down
    remove_concurrent_index :snippets, [:id, :type]
  end
end
