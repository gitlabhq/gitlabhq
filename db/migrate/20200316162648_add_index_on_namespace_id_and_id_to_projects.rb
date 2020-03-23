# frozen_string_literal: true

class AddIndexOnNamespaceIdAndIdToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:namespace_id, :id]
    remove_concurrent_index :projects, :namespace_id
  end

  def down
    add_concurrent_index :projects, :namespace_id
    remove_concurrent_index :projects, [:namespace_id, :id]
  end
end
