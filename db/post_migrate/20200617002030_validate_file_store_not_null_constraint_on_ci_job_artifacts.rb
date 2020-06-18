# frozen_string_literal: true

class ValidateFileStoreNotNullConstraintOnCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_check_constraint(:ci_job_artifacts, :check_27f0f6dbab)
  end

  def down
    # no-op
  end
end
