# frozen_string_literal: true

class AddFkOnEventsPersonalNamespaceIdGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    return unless Gitlab.com_except_jh?

    add_concurrent_foreign_key :events, :namespaces, column: :personal_namespace_id, on_delete: :cascade
  end

  def down
    return unless Gitlab.com_except_jh?

    with_lock_retries { remove_foreign_key :events, column: :personal_namespace_id }
  end
end
