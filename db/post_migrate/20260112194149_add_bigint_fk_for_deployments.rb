# frozen_string_literal: true

class AddBigintFkForDeployments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'deployments'
  COLUMN = :environment_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    add_concurrent_foreign_key(
      :deployments,
      :environments,
      column: :environment_id_convert_to_bigint,
      target_column: :id,
      name: :fk_009fd21147_tmp,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end

  def down
    remove_foreign_key_if_exists(
      :deployments,
      :environments,
      name: :fk_009fd21147_tmp,
      reverse_lock_order: true
    )
  end
end
