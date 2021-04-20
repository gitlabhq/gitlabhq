# frozen_string_literal: true

class DropTemporaryIndexOnCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX = 'tmp_build_stage_position_index'

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX
  end

  def down
    add_concurrent_index :ci_builds, [:stage_id, :stage_idx], where: 'stage_idx IS NOT NULL', name: INDEX
  end
end
