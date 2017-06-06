class AddStageIdToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :ci_builds, :stage_id, :integer

    add_concurrent_foreign_key :ci_builds, :ci_stages, column: :stage_id, on_delete: :cascade
    add_concurrent_index :ci_builds, :stage_id
  end

  def down
    remove_foreign_key :ci_builds, column: :stage_id
    remove_concurrent_index :ci_builds, :stage_id

    remove_column :ci_builds, :stage_id, :integer
  end
end
