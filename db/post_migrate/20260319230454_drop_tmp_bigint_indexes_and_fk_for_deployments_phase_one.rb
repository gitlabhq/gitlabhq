# frozen_string_literal: true

class DropTmpBigintIndexesAndFkForDeploymentsPhaseOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = 'deployments'
  COLUMNS = %w[id environment_id].freeze
  INDEXES = %w[
    deployment_id_pkey
    index_deployments_for_visible_scope
    index_deployments_on_environment_id_and_id
    index_deployments_on_environment_id_and_ref
    index_deployments_on_environment_id_status_and_finished_at
    index_deployments_on_environment_id_status_and_id
    index_deployments_on_environment_status_sha
    index_deployments_on_project_and_environment_and_updated_at_id
    index_deployments_on_project_id_and_id
    index_deployments_on_project_id_and_updated_at_and_id
    index_deployments_on_id_and_status_and_created_at
  ].freeze

  def up
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('integer')

    unless can_execute_on?(:deployments)
      raise StandardError,
        "Wraparound prevention vacuum detected on deployments table. Please try again later."
    end

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index))
    end

    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        :deployments,
        :environments,
        name: :fk_009fd21147_tmp,
        reverse_lock_order: true
      )
    end
  end

  def down; end

  private

  def bigint_columns_all_exist?
    if COLUMNS.all? { |column| column_exists?(TABLE_NAME, convert_to_bigint_column(column)) }
      true
    else
      say "Not all conversion columns found - migration skipped"
      false
    end
  end

  def bigint_columns_match_type?(column_type)
    if COLUMNS.all? { |column| column_for(TABLE_NAME, convert_to_bigint_column(column)).sql_type == column_type }
      true
    else
      say "Columns do not match type - migration skipped"
      false
    end
  end
end
