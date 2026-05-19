# frozen_string_literal: true

class RetryRemoveFkNamespacesFileTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  FOREIGN_KEY_NAME = 'fk_319256d87a'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :namespaces, :projects,
        column: :file_template_project_id, name: FOREIGN_KEY_NAME, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key :namespaces, :projects,
      column: :file_template_project_id, on_delete: :nullify, name: FOREIGN_KEY_NAME
  end
end
