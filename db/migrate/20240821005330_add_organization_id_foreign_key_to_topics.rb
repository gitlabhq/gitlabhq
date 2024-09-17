# frozen_string_literal: true

class AddOrganizationIdForeignKeyToTopics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:topics, :organizations, column: :organization_id, on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:topics, column: :organization_id)
    end
  end
end
