# frozen_string_literal: true

class ValidateFkCiBuildTraceMetadataPCiJobArtifacts < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    validate_foreign_key(:ci_build_trace_metadata, nil, name: :tmp_fk_21d25cac1a_p)
  end

  def down
    # no-op
  end
end
