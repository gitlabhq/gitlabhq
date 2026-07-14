# frozen_string_literal: true

class RemoveCdEnvironmentsLegacyColumns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_environments

  def up
    with_lock_retries do
      remove_column TABLE_NAME, :cluster_agent_id, if_exists: true
      remove_column TABLE_NAME, :platform_type, if_exists: true
      remove_column TABLE_NAME, :region, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :cluster_agent_id, :bigint unless column_exists?(TABLE_NAME, :cluster_agent_id)
      add_column TABLE_NAME, :platform_type, :smallint, default: 0 unless column_exists?(TABLE_NAME, :platform_type)
      add_column TABLE_NAME, :region, :text unless column_exists?(TABLE_NAME, :region)
    end

    add_concurrent_index TABLE_NAME, :cluster_agent_id, name: :index_cd_environments_on_cluster_agent_id
    add_check_constraint TABLE_NAME, 'char_length(region) <= 255', :check_1e9426d39c
  end
end
