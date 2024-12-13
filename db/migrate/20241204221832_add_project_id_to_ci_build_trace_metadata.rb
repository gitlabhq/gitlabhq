# frozen_string_literal: true

class AddProjectIdToCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :p_ci_build_trace_metadata, :project_id, :bigint
  end
end
