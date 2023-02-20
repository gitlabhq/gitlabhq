# frozen_string_literal: true

class RemoveNamespacesApplicationSettingsInstanceAdministratorsGroupIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:application_settings, :namespaces, name: "fk_e8a145f3a7")

    with_lock_retries do
      execute('LOCK namespaces, application_settings IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:application_settings, :namespaces, name: "fk_e8a145f3a7")
    end
  end

  def down
    add_concurrent_foreign_key(:application_settings, :namespaces,
      name: "fk_e8a145f3a7", column: :instance_administrators_group_id,
      target_column: :id, on_delete: :nullify)
  end
end
