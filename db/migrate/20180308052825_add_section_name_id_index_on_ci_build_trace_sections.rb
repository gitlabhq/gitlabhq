class AddSectionNameIdIndexOnCiBuildTraceSections < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_ci_build_trace_sections_on_section_name_id'

  disable_ddl_transaction!

  def up
    # MySQL may already have this as a foreign key
    unless index_exists?(:ci_build_trace_sections, :section_name_id, name: INDEX_NAME)
      add_concurrent_index :ci_build_trace_sections, :section_name_id, name: INDEX_NAME
    end
  end

  def down
    # We cannot remove index for MySQL because it's needed for foreign key
    if Gitlab::Database.postgresql?
      remove_concurrent_index :ci_build_trace_sections, :section_name_id, name: INDEX_NAME
    end
  end
end
