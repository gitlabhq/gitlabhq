# frozen_string_literal: true

class AddCheckConstraintCdArtifactSourcesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_project_id_present_when_internal_pipeline'

  def up
    add_check_constraint(
      :cd_artifact_sources,
      'NOT (source_type = 0 AND project_id IS NULL)',
      CONSTRAINT_NAME,
      validate: true
    )
  end

  def down
    remove_check_constraint(:cd_artifact_sources, CONSTRAINT_NAME)
  end
end
