# frozen_string_literal: true

class AddIndexApplicationSettingsDuoTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    add_concurrent_index :application_settings,
      :duo_template_project_id,
      name: :idx_application_settings_on_duo_template_project_id
  end

  def down
    remove_concurrent_index_by_name :application_settings,
      :idx_application_settings_on_duo_template_project_id
  end
end
