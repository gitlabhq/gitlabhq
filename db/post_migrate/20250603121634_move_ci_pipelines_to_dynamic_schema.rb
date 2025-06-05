# frozen_string_literal: true

class MoveCiPipelinesToDynamicSchema < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.1'
  skip_require_disable_ddl_transactions!

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_NAME = :ci_pipelines

  RENAMED_PARTITION_INDEX_MAP = [
    {
      old_name: :ci_pipelines_merge_request_id_idx,
      new_name: :index_ci_pipelines_on_merge_request_id
    },
    {
      old_name: :ci_pipelines_pipeline_schedule_id_id_idx,
      new_name: :index_ci_pipelines_on_pipeline_schedule_id_and_id
    },
    {
      old_name: :ci_pipelines_project_id_id_idx,
      new_name: :index_ci_pipelines_on_project_id_and_id_desc
    },
    {
      old_name: :ci_pipelines_project_id_iid_partition_id_idx,
      new_name: :index_ci_pipelines_on_project_id_and_iid_and_partition_id
    },
    {
      old_name: :ci_pipelines_project_id_ref_status_id_idx,
      new_name: :index_ci_pipelines_on_project_id_and_ref_and_status_and_id
    },
    {
      old_name: :ci_pipelines_project_id_sha_idx,
      new_name: :index_ci_pipelines_on_project_id_and_sha
    },
    {
      old_name: :ci_pipelines_project_id_source_idx,
      new_name: :index_ci_pipelines_on_project_id_and_source
    },
    {
      old_name: :ci_pipelines_project_id_status_config_source_idx,
      new_name: :index_ci_pipelines_on_project_id_and_status_and_config_source
    },
    {
      old_name: :ci_pipelines_project_id_status_created_at_idx,
      new_name: :index_ci_pipelines_on_project_id_and_status_and_created_at
    },
    {
      old_name: :ci_pipelines_project_id_status_updated_at_idx,
      new_name: :index_ci_pipelines_on_project_id_and_status_and_updated_at
    },
    {
      old_name: :ci_pipelines_project_id_user_id_status_ref_idx,
      new_name: :index_ci_pipelines_on_project_id_and_user_id_and_status_and_ref
    },
    {
      old_name: :ci_pipelines_project_id_ref_id_idx,
      new_name: :index_ci_pipelines_on_project_idandrefandiddesc
    },
    {
      old_name: :ci_pipelines_user_id_created_at_config_source_idx,
      new_name: :index_ci_pipelines_on_user_id_and_created_at_and_config_source
    },
    {
      old_name: :ci_pipelines_user_id_created_at_source_idx,
      new_name: :index_ci_pipelines_on_user_id_and_created_at_and_source
    },
    {
      old_name: :ci_pipelines_user_id_id_idx,
      new_name: :index_ci_pipelines_on_user_id_and_id_and_cancelable_status
    },
    {
      old_name: :ci_pipelines_user_id_id_idx1,
      new_name: :index_ci_pipelines_on_user_id_and_id_desc_and_user_not_verified
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
        CREATE TABLE IF NOT EXISTS #{TABLE_NAME} PARTITION OF p_#{TABLE_NAME} FOR VALUES IN (100, 101, 102);
      SQL

      restore_index_names
      track_record_deletions_override_table_name(TABLE_NAME, "p_#{TABLE_NAME}")
    end
  end

  private

  def remove_dynamic_partitions
    drop_partition(100)
    drop_partition(101)
    drop_partition(102)
  end

  def drop_partition(number)
    identifier = "#{DYNAMIC_SCHEMA}.#{TABLE_NAME}_#{number}"
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
