# frozen_string_literal: true

class FixMisnamedCiIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  # Mapping of table names -> [index columns, old name, expected name]
  # rubocop:disable Layout/LineLength -- More readable on single line
  INDEXES_TO_RENAME = {
    'p_ci_builds_metadata' => [
      %w[build_id p_ci_builds_metadata_build_id_convert_to_bigint_id_convert__idx p_ci_builds_metadata_build_id_id_idx],
      %w[build_id p_ci_builds_metadata_build_id_convert_to_bigint_idx p_ci_builds_metadata_build_id_idx]
    ],
    'p_ci_pipelines' => [
      [%w[ci_ref_id id], 'p_ci_pipelines_ci_ref_id_id_convert_to_bigint_idx', 'p_ci_pipelines_ci_ref_id_id_idx'],
      [%w[ci_ref_id id source status], 'p_ci_pipelines_ci_ref_id_id_convert_to_bigint_source_status_idx', 'p_ci_pipelines_ci_ref_id_id_source_status_idx'],
      [%w[id], 'p_ci_pipelines_id_convert_to_bigint_idx', 'p_ci_pipelines_id_idx'],
      [%w[pipeline_schedule_id id], 'p_ci_pipelines_pipeline_schedule_id_id_convert_to_bigint_idx', 'p_ci_pipelines_pipeline_schedule_id_id_idx'],
      [%w[project_id id], 'p_ci_pipelines_project_id_id_convert_to_bigint_idx', 'p_ci_pipelines_project_id_id_idx'],
      [%w[project_id ref id], 'p_ci_pipelines_project_id_ref_id_convert_to_bigint_idx', 'p_ci_pipelines_project_id_ref_id_idx'],
      [%w[project_id ref status id], 'p_ci_pipelines_project_id_ref_status_id_convert_to_bigint_idx', 'p_ci_pipelines_project_id_ref_status_id_idx'],
      [%w[status id], 'p_ci_pipelines_status_id_convert_to_bigint_idx', 'p_ci_pipelines_status_id_idx'],
      [%w[user_id id], 'p_ci_pipelines_user_id_id_convert_to_bigint_idx', 'p_ci_pipelines_user_id_id_idx'],
      [%w[user_id id], 'p_ci_pipelines_user_id_id_convert_to_bigint_idx1', 'p_ci_pipelines_user_id_id_idx1']
    ],
    'p_ci_stages' => [
      [%w[pipeline_id id], 'p_ci_stages_pipeline_id_convert_to_bigint_id_idx', 'p_ci_stages_pipeline_id_id_idx'],
      [%w[pipeline_id position], 'p_ci_stages_pipeline_id_convert_to_bigint_position_idx', 'p_ci_stages_pipeline_id_position_idx']
    ]
  }.freeze
  # rubocop:enable Layout/LineLength

  def up
    with_each_index do |table, columns, old_name, new_name|
      next if index_exists?(table, columns, name: new_name)
      next unless index_exists?(table, columns, name: old_name)

      with_lock_retries { rename_index(table, old_name, new_name) }
    end
  end

  # We have no way of tracking which misnamed indexes existed before the migration,
  # so let's not try to restore the previous, incorrect state.
  def down; end

  private

  def with_each_index
    INDEXES_TO_RENAME.each do |table, indexes|
      indexes.each do |index_info|
        columns, old_name, new_name = index_info
        yield table, columns, old_name, new_name
      end
    end
  end
end
