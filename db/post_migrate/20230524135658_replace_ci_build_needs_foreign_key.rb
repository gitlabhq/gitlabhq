# frozen_string_literal: true

class ReplaceCiBuildNeedsForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_build_needs, :p_ci_builds,
      name: 'temp_fk_rails_3cf221d4ed_p',
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_build_needs,
      name: 'temp_fk_rails_3cf221d4ed_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_build_needs, name: 'temp_fk_rails_3cf221d4ed_p'
    remove_foreign_key :ci_build_needs, name: 'temp_fk_rails_3cf221d4ed_p'
  end
end
