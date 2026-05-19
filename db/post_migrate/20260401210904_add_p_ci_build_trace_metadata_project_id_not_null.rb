# frozen_string_literal: true

class AddPCiBuildTraceMetadataProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :p_ci_build_trace_metadata, :project_id
  end

  def down
    remove_not_null_constraint :p_ci_build_trace_metadata, :project_id
  end
end
