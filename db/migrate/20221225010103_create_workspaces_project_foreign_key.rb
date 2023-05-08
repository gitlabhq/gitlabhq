# frozen_string_literal: true

class CreateWorkspacesProjectForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # NOTE: All workspace foreign key references are currently `on_delete: :cascade`, because we have no support or
    #       testing around null values. However, in the future we may want to switch these to nullify, especially
    #       once we start introducing logging, metrics, billing, etc. around workspaces.
    add_concurrent_foreign_key :workspaces, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :workspaces, column: :project_id
    end
  end
end
