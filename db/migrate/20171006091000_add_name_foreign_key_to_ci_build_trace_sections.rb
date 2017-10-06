class AddNameForeignKeyToCiBuildTraceSections < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_build_trace_sections, :ci_build_trace_section_names, column: :section_name_id)
  end

  def down
    remove_foreign_key(:ci_build_trace_sections, column: :section_name_id)
  end
end
