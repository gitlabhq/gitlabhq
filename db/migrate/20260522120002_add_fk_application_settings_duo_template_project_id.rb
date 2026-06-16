# frozen_string_literal: true

class AddFkApplicationSettingsDuoTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :application_settings, :projects,
      column: :duo_template_project_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :application_settings, :projects,
        column: :duo_template_project_id
    end
  end
end
