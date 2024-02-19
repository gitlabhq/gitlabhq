# frozen_string_literal: true

class ValidateFkCiJobArtifactStatesPCiJobArtifacts < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    validate_foreign_key(:ci_job_artifact_states, nil, name: :tmp_fk_rails_80a9cba3b2_p)
  end

  def down
    # no-op
  end
end
