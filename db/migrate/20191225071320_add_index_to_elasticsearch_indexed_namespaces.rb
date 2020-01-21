# frozen_string_literal: true

class AddIndexToElasticsearchIndexedNamespaces < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:elasticsearch_indexed_namespaces, :created_at)
  end

  def down
    remove_concurrent_index(:elasticsearch_indexed_namespaces, :created_at)
  end
end
