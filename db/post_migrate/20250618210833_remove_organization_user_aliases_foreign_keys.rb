# frozen_string_literal: true

class RemoveOrganizationUserAliasesForeignKeys < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  FOREIGN_KEY = 'fk_31b4eb5ec5'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :organization_user_aliases,
        :users,
        name: FOREIGN_KEY,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :organization_user_aliases,
      :users,
      name: FOREIGN_KEY,
      column: :user_id,
      on_delete: :cascade
    )
  end
end
