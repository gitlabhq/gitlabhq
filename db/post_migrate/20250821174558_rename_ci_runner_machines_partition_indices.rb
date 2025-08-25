# frozen_string_literal: true

class RenameCiRunnerMachinesPartitionIndices < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.4'

  disable_ddl_transaction!

  INSTANCE_INDICES = {
    instance_type_ci_runner_machi_runner_id_runner_type_system__idx:
      :index_inst_type_ci_runner_machines_on_runner_id_type_system_xid,
    instance_type_ci_runner_machin_substring_version_runner_id_idx1:
      :index_instance_type_ci_runner_machines_on_minor_version,
    instance_type_ci_runner_machin_substring_version_runner_id_idx2:
      :index_instance_type_ci_runner_machines_on_patch_version,
    instance_type_ci_runner_machine_substring_version_runner_id_idx:
      :index_instance_type_ci_runner_machines_on_major_version,
    instance_type_ci_runner_machines_687967fa8a_contacted_at_id_idx:
      :index_inst_type_ci_runner_machines_on_contacted_at_desc_id_desc,
    instance_type_ci_runner_machines_687967fa8a_created_at_id_idx:
      :idx_instance_type_ci_runner_machines_on_created_at_and_id_desc,
    instance_type_ci_runner_machines_687967fa8a_sharding_key_id_idx:
      :idx_inst_type_ci_runner_machines_on_sharding_key_when_not_null,
    instance_type_ci_runner_machines_687967fa8a_version_idx: :index_instance_type_ci_runner_machines_on_version,
    index_012094097c: :index_instance_type_ci_runner_machines_on_executor_type,
    index_d2746151f0: :index_instance_type_ci_runner_machines_on_ip_address,
    index_f4903d2246: :index_instance_type_ci_runner_machines_on_organization_id
  }.freeze

  GROUP_INDICES = {
    group_type_ci_runner_machines_687967fa8a_contacted_at_id_idx:
      :idx_group_type_ci_runner_machines_on_contacted_at_desc_id_desc,
    group_type_ci_runner_machines_687967fa8a_created_at_id_idx:
      :index_group_type_ci_runner_machines_on_created_at_and_id_desc,
    group_type_ci_runner_machines_687967fa8a_sharding_key_id_idx:
      :idx_group_type_ci_runner_machines_on_sharding_key_when_not_null,
    group_type_ci_runner_machines_687967fa8a_version_idx: :index_group_type_ci_runner_machines_on_version,
    group_type_ci_runner_machines_6_substring_version_runner_id_idx:
      :index_group_type_ci_runner_machines_on_major_version,
    group_type_ci_runner_machines__substring_version_runner_id_idx1:
      :index_group_type_ci_runner_machines_on_minor_version,
    group_type_ci_runner_machines__substring_version_runner_id_idx2:
      :index_group_type_ci_runner_machines_on_patch_version,
    group_type_ci_runner_machines_runner_id_runner_type_system__idx:
      :idx_group_type_ci_runner_machines_on_runner_id_type_system_xid,
    index_aa3b4fe8c6: :index_group_type_ci_runner_machines_on_executor_type,
    index_ee7c87e634: :index_group_type_ci_runner_machines_on_ip_address,
    index_8cc4cbb7d2: :index_group_type_ci_runner_machines_on_organization_id
  }.freeze

  PROJECT_INDICES = {
    project_type_ci_runner_machin_runner_id_runner_type_system__idx:
      :index_proj_type_ci_runner_machines_on_runner_id_type_system_xid,
    project_type_ci_runner_machine_substring_version_runner_id_idx1:
      :index_project_type_ci_runner_machines_on_minor_version,
    project_type_ci_runner_machine_substring_version_runner_id_idx2:
      :index_project_type_ci_runner_machines_on_patch_version,
    project_type_ci_runner_machines_687967fa8a_contacted_at_id_idx:
      :index_proj_type_ci_runner_machines_on_contacted_at_desc_id_desc,
    project_type_ci_runner_machines_687967fa8a_created_at_id_idx:
      :index_project_type_ci_runner_machines_on_created_at_and_id_desc,
    project_type_ci_runner_machines_687967fa8a_sharding_key_id_idx:
      :idx_proj_type_ci_runner_machines_on_sharding_key_when_not_null,
    project_type_ci_runner_machines_687967fa8a_version_idx:
      :index_project_type_ci_runner_machines_on_version,
    project_type_ci_runner_machines_substring_version_runner_id_idx:
      :index_project_type_ci_runner_machines_on_major_version,
    index_d58435d85e: :index_project_type_ci_runner_machines_on_executor_type,
    index_053d12f7ee: :index_project_type_ci_runner_machines_on_ip_address,
    index_e4459c2bb7: :index_project_type_ci_runner_machines_on_organization_id
  }.freeze

  def up
    [INSTANCE_INDICES, GROUP_INDICES, PROJECT_INDICES].each do |indices|
      with_lock_retries do
        statements = indices.map { |from, to| alter_index_statement(from, to) }

        connection.execute(statements.join(';'))
      end
    end
  end

  def down
    [INSTANCE_INDICES, GROUP_INDICES, PROJECT_INDICES].reverse_each do |indices|
      with_lock_retries do
        statements = indices.map { |from, to| alter_index_statement(to, from) }

        connection.execute(statements.reverse.join(';'))
      end
    end
  end

  private

  def alter_index_statement(from, to)
    <<~SQL
      ALTER INDEX IF EXISTS #{connection.quote_table_name("#{connection.current_schema}.#{connection.quote_column_name(from)}")}
                  RENAME TO #{connection.quote_column_name(to)}
    SQL
  end
end
