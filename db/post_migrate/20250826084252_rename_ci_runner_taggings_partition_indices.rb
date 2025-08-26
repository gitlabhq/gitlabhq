# frozen_string_literal: true

class RenameCiRunnerTaggingsPartitionIndices < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  INSTANCE_INDICES = {
    ci_runner_taggings_instance_ty_tag_id_runner_id_runner_type_idx:
      :idx_ci_runner_taggings_inst_type_on_tag_id_runner_id_and_type,
    ci_runner_taggings_instance_type_runner_id_runner_type_idx:
      :idx_ci_runner_taggings_instance_type_on_runner_id_and_type,
    ci_runner_taggings_instance_type_sharding_key_id_idx: :index_ci_runner_taggings_instance_type_on_sharding_key_id,
    index_8f3cd552cd: :index_ci_runner_taggings_instance_type_on_organization_id
  }.freeze

  GROUP_INDICES = {
    ci_runner_taggings_group_type_tag_id_runner_id_runner_type_idx:
      :idx_ci_runner_taggings_group_type_on_tag_id_runner_id_and_type,
    ci_runner_taggings_group_type_runner_id_runner_type_idx:
      :idx_ci_runner_taggings_group_type_on_runner_id_and_runner_type,
    ci_runner_taggings_group_type_sharding_key_id_idx: :index_ci_runner_taggings_group_type_on_sharding_key_id,
    index_03bce7b65b: :index_ci_runner_taggings_group_type_on_organization_id
  }.freeze

  PROJECT_INDICES = {
    ci_runner_taggings_project_typ_tag_id_runner_id_runner_type_idx:
      :idx_ci_runner_taggings_proj_type_on_tag_id_runner_id_and_type,
    ci_runner_taggings_project_type_runner_id_runner_type_idx:
      :index_ci_runner_taggings_project_type_on_runner_id_runner_type,
    ci_runner_taggings_project_type_sharding_key_id_idx: :index_ci_runner_taggings_project_type_on_sharding_key_id,
    index_934f0e59cf: :index_ci_runner_taggings_project_type_on_organization_id
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
