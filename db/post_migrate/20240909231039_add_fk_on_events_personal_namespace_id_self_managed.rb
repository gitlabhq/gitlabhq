# frozen_string_literal: true

class AddFkOnEventsPersonalNamespaceIdSelfManaged < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  TABLE_NAME = :events

  def up
    return if Gitlab.com_except_jh?

    add_concurrent_foreign_key TABLE_NAME, :namespaces, column: :personal_namespace_id, on_delete: :cascade
  end

  def down
    return if Gitlab.com_except_jh?

    with_lock_retries { remove_foreign_key TABLE_NAME, column: :personal_namespace_id }
  end
end
