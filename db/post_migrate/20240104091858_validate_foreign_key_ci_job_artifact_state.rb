# frozen_string_literal: true

class ValidateForeignKeyCiJobArtifactState < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  FK_NAME = :fk_rails_80a9cba3b2_p

  def up
    validate_foreign_key(:ci_job_artifact_states, [:partition_id, :job_artifact_id], name: FK_NAME)
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
