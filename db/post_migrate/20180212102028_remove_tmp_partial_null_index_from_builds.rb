class RemoveTmpPartialNullIndexFromBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:ci_builds, 'tmp_stage_id_partial_null_index')
  end

  def down
    add_concurrent_index(:ci_builds, :stage_id, where: 'stage_id IS NULL',
                                                name: 'tmp_stage_id_partial_null_index')
  end
end
