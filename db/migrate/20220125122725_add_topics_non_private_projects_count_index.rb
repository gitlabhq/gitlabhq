# frozen_string_literal: true

class AddTopicsNonPrivateProjectsCountIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_topics_non_private_projects_count'

  disable_ddl_transaction!

  def up
    add_concurrent_index :topics, [:non_private_projects_count, :id], order: { non_private_projects_count: :desc }, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :topics, INDEX_NAME
  end
end
