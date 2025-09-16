# frozen_string_literal: true

class RenameCiRunnerPartitionIndices < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  INSTANCE_INDICES = {
    instance_type_ci_runners_e59bb2812d_active_id_idx: :idx_instance_type_ci_runners_on_active_and_id,
    instance_type_ci_runners_e59bb2812d_contacted_at_id_idx: :idx_instance_type_ci_runners_on_contacted_at_and_id_desc,
    instance_type_ci_runners_e59bb2812d_contacted_at_id_idx1:
      :idx_instance_type_ci_runners_on_contacted_at_id_where_inactive,
    instance_type_ci_runners_e59bb2812d_contacted_at_id_idx2:
      :index_instance_type_ci_runners_on_contacted_at_desc_and_id_desc,
    instance_type_ci_runners_e59bb2812d_created_at_id_idx: :index_instance_type_ci_runners_on_created_at_and_id_desc,
    instance_type_ci_runners_e59bb2812d_created_at_id_idx1:
      :index_instance_type_ci_runners_on_created_at_id_where_inactive,
    instance_type_ci_runners_e59bb2812d_created_at_id_idx2:
      :index_instance_type_ci_runners_on_created_at_desc_and_id_desc,
    instance_type_ci_runners_e59bb2812d_creator_id_idx: :index_instance_type_ci_runners_on_creator_id_where_not_null,
    instance_type_ci_runners_e59bb2812d_description_idx: :index_instance_type_ci_runners_on_description_trigram,
    instance_type_ci_runners_e59bb2812d_locked_idx: :index_instance_type_ci_runners_on_locked,
    instance_type_ci_runners_e59bb2812d_sharding_key_id_idx:
      :idx_instance_type_ci_runners_on_sharding_key_id_when_not_null,
    instance_type_ci_runners_e59bb2812d_token_expires_at_id_idx:
      :index_instance_type_ci_runners_on_token_expires_at_and_id_desc,
    instance_type_ci_runners_e59bb2812d_token_expires_at_id_idx1:
      :idx_instance_type_ci_runners_on_token_expires_at_desc_id_desc,
    instance_type_ci_runners_e59bb2812d_token_runner_type_idx:
      :idx_instance_type_ci_runners_on_token_runner_type_when_not_null,
    instance_type_ci_runners_e59bb2_token_encrypted_runner_type_idx:
      :idx_instance_type_ci_runners_on_token_encrypted_and_runner_type,
    index_92f173730f: :index_instance_type_ci_runners_on_organization_id
  }.freeze

  GROUP_INDICES = {
    group_type_ci_runners_e59bb2812d_contacted_at_id_idx2:
      :index_group_type_ci_runners_on_contacted_at_desc_and_id_desc,
    group_type_ci_runners_e59bb2812_token_encrypted_runner_type_idx:
      :index_group_type_ci_runners_on_token_encrypted_and_runner_type,
    group_type_ci_runners_e59bb2812d_active_id_idx: :index_group_type_ci_runners_on_active_and_id,
    group_type_ci_runners_e59bb2812d_contacted_at_id_idx: :index_group_type_ci_runners_on_contacted_at_and_id_desc,
    group_type_ci_runners_e59bb2812d_contacted_at_id_idx1:
      :idx_group_type_ci_runners_on_contacted_at_and_id_where_inactive,
    group_type_ci_runners_e59bb2812d_created_at_id_idx: :index_group_type_ci_runners_on_created_at_and_id_desc,
    group_type_ci_runners_e59bb2812d_created_at_id_idx1:
      :index_group_type_ci_runners_on_created_at_and_id_where_inactive,
    group_type_ci_runners_e59bb2812d_created_at_id_idx2: :index_group_type_ci_runners_on_created_at_desc_and_id_desc,
    group_type_ci_runners_e59bb2812d_creator_id_idx: :index_group_type_ci_runners_on_creator_id_where_not_null,
    group_type_ci_runners_e59bb2812d_description_idx: :index_group_type_ci_runners_on_description_trigram,
    group_type_ci_runners_e59bb2812d_locked_idx: :idx_group_type_ci_runners_on_locked,
    group_type_ci_runners_e59bb2812d_sharding_key_id_idx: :idx_group_type_ci_runners_on_sharding_key_id_when_not_null,
    group_type_ci_runners_e59bb2812d_token_expires_at_id_idx:
      :idx_group_type_ci_runners_on_token_expires_at_and_id_desc,
    group_type_ci_runners_e59bb2812d_token_expires_at_id_idx1:
      :idx_group_type_ci_runners_on_token_expires_at_desc_and_id_desc,
    group_type_ci_runners_e59bb2812d_token_runner_type_idx:
      :idx_group_type_ci_runners_on_token_runner_type_when_not_null,
    index_a3343eff0d: :index_group_type_ci_runners_on_organization_id
  }.freeze

  PROJECT_INDICES = {
    project_type_ci_runners_e59bb2812d_active_id_idx: :idx_project_type_ci_runners_on_active_and_id,
    project_type_ci_runners_e59bb2812d_contacted_at_id_idx: :idx_project_type_ci_runners_on_contacted_at_and_id_desc,
    project_type_ci_runners_e59bb2812d_contacted_at_id_idx1:
      :idx_project_type_ci_runners_on_contacted_at_id_where_inactive,
    project_type_ci_runners_e59bb2812d_contacted_at_id_idx2:
      :idx_project_type_ci_runners_on_contacted_at_desc_and_id_desc,
    project_type_ci_runners_e59bb2812d_created_at_id_idx: :index_project_type_ci_runners_on_created_at_and_id_desc,
    project_type_ci_runners_e59bb2812d_created_at_id_idx1:
      :idx_project_type_ci_runners_on_created_at_and_id_where_inactive,
    project_type_ci_runners_e59bb2812d_created_at_id_idx2: :idx_project_type_ci_runners_on_created_at_desc_and_id_desc,
    project_type_ci_runners_e59bb2812d_creator_id_idx: :index_project_type_ci_runners_on_creator_id_where_not_null,
    project_type_ci_runners_e59bb2812d_description_idx: :index_project_type_ci_runners_on_description_trigram,
    project_type_ci_runners_e59bb2812d_locked_idx: :index_project_type_ci_runners_on_locked,
    project_type_ci_runners_e59bb2812d_sharding_key_id_idx:
      :idx_project_type_ci_runners_on_sharding_key_id_when_not_null,
    project_type_ci_runners_e59bb2812d_token_expires_at_id_idx:
      :idx_project_type_ci_runners_on_token_expires_at_and_id_desc,
    project_type_ci_runners_e59bb2812d_token_expires_at_id_idx1:
      :idx_project_type_ci_runners_on_token_expires_at_desc_id_desc,
    project_type_ci_runners_e59bb2812d_token_runner_type_idx:
      :idx_project_type_ci_runners_on_token_runner_type_when_not_null,
    project_type_ci_runners_e59bb28_token_encrypted_runner_type_idx:
      :idx_project_type_ci_runners_on_token_encrypted_and_runner_type,
    index_11eb9d1747: :index_project_type_ci_runners_on_organization_id
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
