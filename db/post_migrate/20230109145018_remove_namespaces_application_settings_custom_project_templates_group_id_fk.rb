# frozen_string_literal: true

class RemoveNamespacesApplicationSettingsCustomProjectTemplatesGroupIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:application_settings, :namespaces, name: "fk_rails_b53e481273")

    with_lock_retries do
      execute('LOCK namespaces, application_settings IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:application_settings, :namespaces, name: "fk_rails_b53e481273")
    end
  end

  def down
    add_concurrent_foreign_key(:application_settings, :namespaces,
      name: "fk_rails_b53e481273", column: :custom_project_templates_group_id,
      target_column: :id, on_delete: :nullify)
  end
end
