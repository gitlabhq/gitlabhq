# frozen_string_literal: true

class ValidateFkCiBuildTraceChunksPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_build_trace_chunks, nil, name: :temp_fk_89e29fa5ee_p
  end

  def down
    # no-op
  end
end
