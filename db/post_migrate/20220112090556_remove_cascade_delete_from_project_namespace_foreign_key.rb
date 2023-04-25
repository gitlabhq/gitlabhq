# frozen_string_literal: true

class RemoveCascadeDeleteFromProjectNamespaceForeignKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TARGET_COLUMN = :project_namespace_id

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, column: TARGET_COLUMN)
    end

    add_concurrent_foreign_key(:projects, :namespaces, column: TARGET_COLUMN, on_delete: :nullify)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, column: TARGET_COLUMN)
    end

    add_concurrent_foreign_key(:projects, :namespaces, column: TARGET_COLUMN, on_delete: :cascade)
  end
end
