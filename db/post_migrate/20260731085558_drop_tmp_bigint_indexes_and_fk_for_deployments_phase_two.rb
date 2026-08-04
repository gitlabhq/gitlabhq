# frozen_string_literal: true

class DropTmpBigintIndexesAndFkForDeploymentsPhaseTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = 'deployments'
  COLUMNS = %w[project_id user_id].freeze
  # Mirrors CreateBigintIndexesForDeploymentsPhaseTwo, so that `down` can
  # recreate exactly what was dropped.
  INDEXES = [
    {
      name: 'index_deployments_on_archived_project_id_iid',
      columns: [:archived, :project_id_convert_to_bigint, :iid]
    },
    {
      name: 'index_deployments_on_project_and_environment_and_updated_at_id',
      columns: [:project_id_convert_to_bigint, :environment_id, :updated_at, :id]
    },
    {
      name: 'index_deployments_on_project_and_finished',
      columns: [:project_id_convert_to_bigint, :finished_at],
      options: { where: "status = 2" }
    },
    {
      name: 'index_deployments_on_project_id_and_id',
      columns: [:project_id_convert_to_bigint, :id],
      options: { order: { id: :desc } }
    },
    {
      name: 'index_deployments_on_project_id_and_iid',
      columns: [:project_id_convert_to_bigint, :iid],
      options: { unique: true }
    },
    {
      name: 'index_deployments_on_project_id_and_status_and_created_at',
      columns: [:project_id_convert_to_bigint, :status, :created_at]
    },
    {
      name: 'index_deployments_on_project_id_and_updated_at_and_id',
      columns: [:project_id_convert_to_bigint, :updated_at, :id],
      options: { order: { updated_at: :desc, id: :desc } }
    },
    {
      name: 'index_deployments_on_user_id_and_status_and_created_at',
      columns: [:user_id_convert_to_bigint, :status, :created_at],
      exclude_com: true
    }
  ].freeze

  def up
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('integer')

    unless can_execute_on?(:deployments)
      raise StandardError,
        "Wraparound prevention vacuum detected on deployments table. Please try again later."
    end

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end

    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        :deployments,
        :projects,
        name: :fk_b9a3851b82_tmp,
        reverse_lock_order: true
      )
    end
  end

  # Restores what `up` dropped, so that the column swap performed in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248015 can still be
  # rolled back after this migration has run.
  def down
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('integer')

    INDEXES.each do |index|
      next if Gitlab.com_except_jh? && index[:exclude_com]

      options = index[:options] || {}
      add_concurrent_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end

    # Recreated as NOT VALID, matching how AddBigintFkForDeploymentsPhaseTwo
    # first added it.
    add_concurrent_foreign_key(
      :deployments,
      :projects,
      column: :project_id_convert_to_bigint,
      target_column: :id,
      name: :fk_b9a3851b82_tmp,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end

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
