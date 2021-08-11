# frozen_string_literal: true

class RenameTablesCiBuildTraceSection < ActiveRecord::Migration[6.1]
  DOWNTIME = false

  def change
    # Shorten deprecated to dep to avoid 'Index name..too long'
    rename_table(:ci_build_trace_sections, :dep_ci_build_trace_sections)
    rename_table(:ci_build_trace_section_names, :dep_ci_build_trace_section_names)
  end
end
