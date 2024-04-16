# frozen_string_literal: true

class RemoveFkEpicsParentId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.11'

  FK_NAME = :fk_25b99c1be3

  # new foreign key added in db/migrate/20240403113607_replace_epics_fk_on_parent_id.rb
  # and validated in db/migrate/20240403114400_validate_epics_fk_on_parent_id_with_on_delete_nullify.rb
  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:epics, column: :parent_id, on_delete: :cascade, name: FK_NAME)
    end
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(:epics, :epics, column: :parent_id, on_delete: :cascade, validate: false, name: FK_NAME)
  end
end
