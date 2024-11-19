# frozen_string_literal: true

class SyncIndexForPipelinesIdBigintRelated < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  TABLE = :ci_pipelines
  INDEXES = [
    {
      name: :idx_ci_pipelines_artifacts_locked_bigint,
      columns: [:ci_ref_id, :id_convert_to_bigint],
      options: { where: 'locked = 1' }
    },
    {
      name: :index_ci_pipelines_for_ondemand_dast_scans_bigint,
      columns: [:id_convert_to_bigint],
      options: { where: 'source = 13' }
    },
    {
      name: :index_ci_pipelines_on_ci_ref_id_and_more_bigint,
      columns: [:ci_ref_id, :id_convert_to_bigint, :source, :status],
      options: { order: { id_convert_to_bigint: :desc }, where: 'ci_ref_id IS NOT NULL' }
    },
    {
      name: :index_ci_pipelines_on_pipeline_schedule_id_and_id_bigint,
      columns: [:pipeline_schedule_id, :id_convert_to_bigint]
    },
    {
      name: :index_ci_pipelines_on_project_id_and_id_desc_bigint,
      columns: [:project_id, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc } }
    },
    {
      name: :idx_ci_pipelines_on_project_id_and_ref_and_status_and_id_bigint,
      columns: [:project_id, :ref, :status, :id_convert_to_bigint]
    },
    {
      name: :index_ci_pipelines_on_project_id_and_ref_and_id_desc_bigint,
      columns: [:project_id, :ref, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc } }
    },
    {
      name: :index_ci_pipelines_on_status_and_id_bigint,
      columns: [:status, :id_convert_to_bigint]
    },
    {
      name: :idx_ci_pipelines_on_user_id_and_id_and_cancelable_status_bigint,
      columns: [:user_id, :id_convert_to_bigint],
      options: { where: "((status)::text = ANY (ARRAY[('running'::character varying)::text, ('waiting_for_resource'::character varying)::text, ('preparing'::character varying)::text, ('pending'::character varying)::text, ('created'::character varying)::text, ('scheduled'::character varying)::text]))" }
    },
    {
      name: :idx_ci_pipelines_on_user_id_and_user_not_verified_bigint,
      columns: [:user_id, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc }, where: "failure_reason = 3" }
    }
  ]

  def up
    INDEXES.each do |index|
      add_concurrent_index(TABLE, index[:columns], name: index[:name], **(index[:options] || {}))
    end
  end

  def down
    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE, index[:name])
    end
  end
end
