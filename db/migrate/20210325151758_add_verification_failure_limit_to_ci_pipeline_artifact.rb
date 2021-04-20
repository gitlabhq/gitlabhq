# frozen_string_literal: true

class AddVerificationFailureLimitToCiPipelineArtifact < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ci_pipeline_artifacts_verification_failure_text_limit'

  def up
    add_text_limit :ci_pipeline_artifacts, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:ci_pipeline_artifacts, CONSTRAINT_NAME)
  end
end
