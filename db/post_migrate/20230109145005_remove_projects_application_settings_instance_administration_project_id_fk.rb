# frozen_string_literal: true

class RemoveProjectsApplicationSettingsInstanceAdministrationProjectIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:application_settings, :projects, name: "fk_rails_7e112a9599")

    with_lock_retries do
      execute('LOCK projects, application_settings IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:application_settings, :projects, name: "fk_rails_7e112a9599")
    end
  end

  def down
    add_concurrent_foreign_key(:application_settings, :projects,
      name: "fk_rails_7e112a9599", column: :instance_administration_project_id,
      target_column: :id, on_delete: :nullify)
  end
end
