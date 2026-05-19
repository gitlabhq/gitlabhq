# frozen_string_literal: true

class RemoveFkNamespacesCustomProjectTemplatesGroupId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :namespaces, :namespaces,
        column: :custom_project_templates_group_id, name: 'fk_e7a0b20a6b'
    end
  end

  def down
    add_concurrent_foreign_key :namespaces, :namespaces,
      column: :custom_project_templates_group_id, on_delete: :nullify, name: 'fk_e7a0b20a6b'
  end
end
