# frozen_string_literal: true

class RemoveUsersVulnerabilitiesAuthorIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_b1de915a15"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:vulnerabilities, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:vulnerabilities, :users,
      name: FOREIGN_KEY_NAME, column: :author_id,
      target_column: :id, on_delete: :nullify)
  end
end
