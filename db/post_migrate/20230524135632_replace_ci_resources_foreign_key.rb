# frozen_string_literal: true

class ReplaceCiResourcesForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_resources, :p_ci_builds,
      name: 'temp_fk_e169a8e3d5_p',
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :nullify,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_resources,
      name: 'temp_fk_e169a8e3d5_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_resources, name: 'temp_fk_e169a8e3d5_p'
    remove_foreign_key :ci_resources, name: 'temp_fk_e169a8e3d5_p'
  end
end
