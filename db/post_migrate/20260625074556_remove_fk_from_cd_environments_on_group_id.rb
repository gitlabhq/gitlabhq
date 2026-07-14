# frozen_string_literal: true

class RemoveFkFromCdEnvironmentsOnGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_environments
  FK_NAME = :fk_a124ccc042

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :namespaces, column: :group_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:namespaces)

    add_concurrent_foreign_key TABLE_NAME, :namespaces,
      column: :group_id, on_delete: :cascade, name: FK_NAME
  end
end
