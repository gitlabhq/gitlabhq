# frozen_string_literal: true

class ValidateFkCiSourcesPipelinesPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_sources_pipelines, nil, name: :temp_fk_be5624bf37_p
  end

  def down
    # no-op
  end
end
