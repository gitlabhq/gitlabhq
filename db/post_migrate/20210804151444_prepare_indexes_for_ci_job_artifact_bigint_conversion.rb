# frozen_string_literal: true

class PrepareIndexesForCiJobArtifactBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    prepare_async_index :ci_job_artifacts, :id_convert_to_bigint, unique: true,
      name: :index_ci_job_artifact_on_id_convert_to_bigint

    prepare_async_index :ci_job_artifacts, [:project_id, :id_convert_to_bigint], where: 'file_type = 18',
      name: :index_ci_job_artifacts_for_terraform_reports_bigint

    prepare_async_index :ci_job_artifacts, :id_convert_to_bigint, where: 'file_type = 18',
      name: :index_ci_job_artifacts_id_for_terraform_reports_bigint

    prepare_async_index :ci_job_artifacts, [:expire_at, :job_id_convert_to_bigint],
      name: :index_ci_job_artifacts_on_expire_at_and_job_id_bigint

    prepare_async_index :ci_job_artifacts, [:job_id_convert_to_bigint, :file_type], unique: true,
      name: :index_ci_job_artifacts_on_job_id_and_file_type_bigint
  end

  def down
    unprepare_async_index_by_name :ci_job_artifacts, :index_ci_job_artifacts_on_job_id_and_file_type_bigint

    unprepare_async_index_by_name :ci_job_artifacts, :index_ci_job_artifacts_on_expire_at_and_job_id_bigint

    unprepare_async_index_by_name :ci_job_artifacts, :index_ci_job_artifacts_id_for_terraform_reports_bigint

    unprepare_async_index_by_name :ci_job_artifacts, :index_ci_job_artifacts_for_terraform_reports_bigint

    unprepare_async_index_by_name :ci_job_artifacts, :index_ci_job_artifact_on_id_convert_to_bigint
  end
end
