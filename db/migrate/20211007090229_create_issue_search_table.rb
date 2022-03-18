# frozen_string_literal: true

class CreateIssueSearchTable < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  def up
    execute <<~SQL
    CREATE TABLE issue_search_data (
      project_id bigint NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
      issue_id bigint NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
      created_at timestamp with time zone DEFAULT NOW() NOT NULL,
      updated_at timestamp with time zone DEFAULT NOW() NOT NULL,
      search_vector tsvector,
      PRIMARY KEY (project_id, issue_id)
    ) PARTITION BY HASH (project_id)
    SQL

    # rubocop: disable Migration/AddIndex
    add_index :issue_search_data, :issue_id
    add_index :issue_search_data, :search_vector, using: :gin, name: 'index_issue_search_data_on_search_vector'
    # rubocop: enable Migration/AddIndex

    create_hash_partitions :issue_search_data, 64
  end

  def down
    drop_table :issue_search_data
  end
end
