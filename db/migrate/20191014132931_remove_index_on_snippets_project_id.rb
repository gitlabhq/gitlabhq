# frozen_string_literal: true

class RemoveIndexOnSnippetsProjectId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :snippets, 'index_snippets_on_project_id'

    # This is an extra index that is not present in db/schema.rb but known to exist on some installs
    remove_concurrent_index_by_name :snippets, :snippets_project_id_idx if index_exists_by_name? :snippets, :snippets_project_id_idx
  end

  def down
    add_concurrent_index :snippets, [:project_id], name: 'index_snippets_on_project_id'
  end
end
