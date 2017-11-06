class AddBuildForeignKeyToCiBuildTraceSections < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_build_trace_sections, :ci_builds, column: :build_id)
  end

  def down
    remove_foreign_key(:ci_build_trace_sections, column: :build_id)
  end
end
