# frozen_string_literal: true

class AddConcurrentIndexToBuildsMetadata < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds_metadata, [:build_id],
                         where: "interruptible = false",
                         name: "index_ci_builds_metadata_on_build_id_and_interruptible_false"
  end

  def down
    remove_concurrent_index_by_name(:ci_builds_metadata, 'index_ci_builds_metadata_on_build_id_and_interruptible_false')
  end
end
