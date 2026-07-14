# frozen_string_literal: true

class RemoveFkFromCdDeploymentsOnVersionSetEntryId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_deployments
  FK_NAME = :fk_d37a491545

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :cd_version_set_entries,
        column: :version_set_entry_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:cd_version_set_entries)

    add_concurrent_foreign_key TABLE_NAME, :cd_version_set_entries,
      column: :version_set_entry_id, on_delete: :cascade, name: FK_NAME
  end
end
