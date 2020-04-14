# frozen_string_literal: true

class AddNotNullConstraintOnFileStoreToCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'ci_job_artifacts_file_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE ci_job_artifacts ADD CONSTRAINT #{CONSTRAINT_NAME} CHECK (file_store IS NOT NULL) NOT VALID;
      SQL
    end
  end

  def down
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE ci_job_artifacts DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME};
      SQL
    end
  end
end
