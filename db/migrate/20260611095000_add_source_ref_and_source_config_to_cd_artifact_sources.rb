# frozen_string_literal: true

class AddSourceRefAndSourceConfigToCdArtifactSources < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  CONSTRAINT_NAME = 'check_cd_artifact_sources_source_config_is_hash'
  PROJECT_CHECK_CONSTRAINT_NAME = 'check_project_id_present_when_internal_pipeline'

  def up
    add_column :cd_artifact_sources, :source_ref, :text, if_not_exists: true

    with_lock_retries do
      add_column :cd_artifact_sources, :source_config, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_text_limit :cd_artifact_sources, :source_ref, 255
    add_check_constraint :cd_artifact_sources, "(jsonb_typeof(source_config) = 'object')", CONSTRAINT_NAME

    # source_type and project_id are being removed (drop deferred to a follow-up).
    # Drop the check constraint that ties them together so the model can stop
    # populating them via ignore_column.
    remove_check_constraint :cd_artifact_sources, PROJECT_CHECK_CONSTRAINT_NAME
    change_column_null :cd_artifact_sources, :source_type, true
  end

  def down
    change_column_null :cd_artifact_sources, :source_type, false
    add_check_constraint :cd_artifact_sources,
      '(NOT ((source_type = 0) AND (project_id IS NULL)))', PROJECT_CHECK_CONSTRAINT_NAME

    remove_check_constraint :cd_artifact_sources, CONSTRAINT_NAME
    remove_column :cd_artifact_sources, :source_ref, if_exists: true

    with_lock_retries do
      remove_column :cd_artifact_sources, :source_config, if_exists: true
    end
  end
end
