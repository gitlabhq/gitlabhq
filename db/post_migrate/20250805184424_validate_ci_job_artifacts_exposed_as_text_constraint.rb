# frozen_string_literal: true

class ValidateCiJobArtifactsExposedAsTextConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    validate_text_limit :p_ci_job_artifacts, :exposed_as
  end

  def down
    # no-op
  end
end
