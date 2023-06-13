# frozen_string_literal: true

class ValidateFkCiBuildTraceMetadataPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_build_trace_metadata, nil, name: :temp_fk_rails_aebc78111f_p
  end

  def down
    # no-op
  end
end
