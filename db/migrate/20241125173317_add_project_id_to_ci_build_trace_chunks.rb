# frozen_string_literal: true

class AddProjectIdToCiBuildTraceChunks < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :ci_build_trace_chunks, :project_id, :bigint
  end
end
