# frozen_string_literal: true

class MoveCiBuildsToDynamicSchema < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.1'
  skip_require_disable_ddl_transactions!

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_NAME = :ci_builds

  RENAMED_PARTITION_INDEX_MAP = [
    {
      old_name: :ci_builds_status_created_at_project_id_idx,
      new_name: :ci_builds_gitlab_monitor_metrics
    },
    {
      old_name: :ci_builds_execution_config_id_idx,
      new_name: :index_0928d9f200
    },
    {
      old_name: :ci_builds_auto_canceled_by_id_idx,
      new_name: :index_ci_builds_on_auto_canceled_by_id
    },
    {
      old_name: :ci_builds_commit_id_stage_idx_created_at_idx,
      new_name: :index_ci_builds_on_commit_id_and_stage_idx_and_created_at
    },
    {
      old_name: :ci_builds_commit_id_status_type_idx,
      new_name: :index_ci_builds_on_commit_id_and_status_and_type
    },
    {
      old_name: :ci_builds_commit_id_type_name_ref_idx,
      new_name: :index_ci_builds_on_commit_id_and_type_and_name_and_ref
    },
    {
      old_name: :ci_builds_commit_id_type_ref_idx,
      new_name: :index_ci_builds_on_commit_id_and_type_and_ref
    },
    {
      old_name: :ci_builds_commit_id_artifacts_expire_at_id_idx,
      new_name: :index_ci_builds_on_commit_id_artifacts_expired_at_and_id
    },
    {
      old_name: :ci_builds_project_id_id_idx,
      new_name: :index_ci_builds_on_project_id_and_id
    },
    {
      old_name: :ci_builds_project_id_name_ref_idx,
      new_name: :index_ci_builds_on_project_id_and_name_and_ref
    },
    {
      old_name: :ci_builds_resource_group_id_status_commit_id_idx,
      new_name: :index_ci_builds_on_resource_group_and_status_and_commit_id
    },
    {
      old_name: :ci_builds_runner_id_id_idx,
      new_name: :index_ci_builds_on_runner_id_and_id_desc
    },
    {
      old_name: :ci_builds_stage_id_idx,
      new_name: :index_ci_builds_on_stage_id
    },
    {
      old_name: :ci_builds_status_type_runner_id_idx,
      new_name: :index_ci_builds_on_status_and_type_and_runner_id
    },
    {
      old_name: :ci_builds_updated_at_idx,
      new_name: :index_ci_builds_on_updated_at
    },
    {
      old_name: :ci_builds_upstream_pipeline_id_idx,
      new_name: :index_ci_builds_on_upstream_pipeline_id
    },
    {
      old_name: :ci_builds_user_id_idx,
      new_name: :index_ci_builds_on_user_id
    },
    {
      old_name: :ci_builds_user_id_created_at_idx,
      new_name: :index_ci_builds_on_user_id_and_created_at_and_type_eq_ci_build
    },
    {
      old_name: :ci_builds_project_id_status_idx,
      new_name: :index_ci_builds_project_id_and_status_for_live_jobs_partial2
    },
    {
      old_name: :ci_builds_runner_id_idx,
      new_name: :index_ci_builds_runner_id_running
    },
    {
      old_name: :ci_builds_user_id_name_idx,
      new_name: :index_partial_ci_builds_on_user_id_name_parser_features
    },
    {
      old_name: :ci_builds_user_id_name_created_at_idx,
      new_name: :index_secure_ci_builds_on_user_id_name_created_at
    },
    {
      old_name: :ci_builds_name_id_idx,
      new_name: :index_security_ci_builds_on_name_and_id_parser_features
    },
    {
      old_name: :ci_builds_scheduled_at_idx,
      new_name: :partial_index_ci_builds_on_scheduled_at_with_scheduled_jobs
    },
    {
      old_name: :ci_builds_token_encrypted_partition_id_idx,
      new_name: :unique_ci_builds_token_encrypted_and_partition_id
    }
  ].freeze

  def up
    return unless can_execute_on?(TABLE_NAME)

    connection.execute(<<~SQL)
      ALTER TABLE IF EXISTS #{TABLE_NAME} SET SCHEMA #{DYNAMIC_SCHEMA};
    SQL
  end

  def down
    return unless can_execute_on?(TABLE_NAME)

    table_identifier = "#{DYNAMIC_SCHEMA}.#{TABLE_NAME}"

    if table_exists?(table_identifier)
      connection.execute(<<~SQL)
        ALTER TABLE IF EXISTS #{table_identifier} SET SCHEMA #{connection.current_schema};
      SQL
    else # In tests we set the database from structure.sql, so the table doesn't exist
      remove_dynamic_partitions
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{TABLE_NAME} PARTITION OF p_#{TABLE_NAME} FOR VALUES IN (100);
      SQL
      restore_index_names
      track_record_deletions_override_table_name(TABLE_NAME, "p_#{TABLE_NAME}")
    end
  end

  private

  def remove_dynamic_partitions
    identifier = "#{DYNAMIC_SCHEMA}.#{TABLE_NAME}_100"
    return unless table_exists?(identifier)

    connection.execute(<<~SQL)
      ALTER TABLE p_#{TABLE_NAME} DETACH PARTITION #{identifier};

      DROP TABLE IF EXISTS #{identifier};
    SQL
  end

  # PostgreSQL is generating different names than what we already have when we create a partition.
  # So we have to rename these indexes to restore original names for previous
  # migrations that depends on the names.
  def restore_index_names
    RENAMED_PARTITION_INDEX_MAP.each do |renamed_index|
      next unless index_name_exists?(TABLE_NAME, renamed_index[:old_name])

      rename_index(TABLE_NAME, renamed_index[:old_name], renamed_index[:new_name])
    end
  end
end
