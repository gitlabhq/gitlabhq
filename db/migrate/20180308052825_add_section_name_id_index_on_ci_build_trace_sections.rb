class AddSectionNameIdIndexOnCiBuildTraceSections < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_ci_build_trace_sections_on_section_name_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_build_trace_sections, :section_name_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :ci_build_trace_sections, :section_name_id, name: INDEX_NAME
  end
end
