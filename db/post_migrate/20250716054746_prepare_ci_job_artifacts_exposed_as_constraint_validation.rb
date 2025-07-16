# frozen_string_literal: true

class PrepareCiJobArtifactsExposedAsConstraintValidation < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  PARTITIONED_TABLE_NAME = :p_ci_job_artifacts
  CONSTRAINT_NAME = 'check_b8fac815e7'

  # Partitioned check constraint to be validated as part of https://gitlab.com/gitlab-org/gitlab/-/issues/549079
  def up
    prepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end
end
