# frozen_string_literal: true

class FixInvalidRecordsCiJobArtifactStates < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  CONSTRAINED_TABLE = 'ci_job_artifact_states'
  REFERENCED_TABLE = 'ci_job_artifacts'

  def up
    return unless should_run?

    each_batch(CONSTRAINED_TABLE) do |batch|
      batch
      .where('NOT EXISTS (SELECT 1 FROM "ci_job_artifacts" WHERE (id = job_artifact_id))')
      .delete_all
    end
  end

  def down
    # no-op
  end

  private

  def should_run?
    Gitlab::Database::PostgresForeignKey
      .by_referenced_table_name(REFERENCED_TABLE)
      .by_constrained_table_name(CONSTRAINED_TABLE)
      .where(is_valid: true)
      .none?
  end
end
