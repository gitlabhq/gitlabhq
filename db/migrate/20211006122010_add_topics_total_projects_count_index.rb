# frozen_string_literal: true

class AddTopicsTotalProjectsCountIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_topics_total_projects_count'

  disable_ddl_transaction!

  def up
    add_concurrent_index :topics, [:total_projects_count, :id], order: { total_projects_count: :desc }, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :topics, INDEX_NAME
  end
end
