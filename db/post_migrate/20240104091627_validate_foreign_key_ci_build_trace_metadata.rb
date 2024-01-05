# frozen_string_literal: true

class ValidateForeignKeyCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  FK_NAME = :fk_21d25cac1a_p

  def up
    validate_foreign_key(:ci_build_trace_metadata, [:partition_id, :trace_artifact_id], name: FK_NAME)
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
