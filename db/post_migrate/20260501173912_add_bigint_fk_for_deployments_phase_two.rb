# frozen_string_literal: true

class AddBigintFkForDeploymentsPhaseTwo < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  TABLE_NAME = 'deployments'
  COLUMN = :project_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

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

  def down
    remove_foreign_key_if_exists(
      :deployments,
      :projects,
      name: :fk_b9a3851b82_tmp,
      reverse_lock_order: true
    )
  end
end
