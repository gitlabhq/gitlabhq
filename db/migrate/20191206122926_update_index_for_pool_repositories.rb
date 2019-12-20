# frozen_string_literal: true

class UpdateIndexForPoolRepositories < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This index is less restrictive then the one we already have, no need to
    # update data.
    add_concurrent_index :pool_repositories, [:source_project_id, :shard_id], unique: true
    remove_concurrent_index :pool_repositories, :source_project_id
  end

  def down
    # Not adding this index as a unique one, since while the new index existed
    # we could have created multiple pool repositories for a project. In that
    # case this rollback would fail.
    add_concurrent_index :pool_repositories, :source_project_id
    remove_concurrent_index :pool_repositories, [:source_project_id, :shard_id], unique: true
  end
end
