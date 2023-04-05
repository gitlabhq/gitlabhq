# frozen_string_literal: true

class AddProjectGroupLinkOnDeleteCascadeFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :project_group_links,
      :namespaces,
      column: :group_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_group_links, column: :group_id
    end
  end
end
