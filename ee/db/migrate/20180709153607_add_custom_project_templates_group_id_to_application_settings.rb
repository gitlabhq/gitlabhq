class AddCustomProjectTemplatesGroupIdToApplicationSettings < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column(:application_settings, :custom_project_templates_group_id, :integer)
    add_foreign_key(:application_settings, :namespaces, column: :custom_project_templates_group_id, on_delete: :nullify) # rubocop: disable Migration/AddConcurrentForeignKey
  end

  def down
    remove_foreign_key(:application_settings, column: :custom_project_templates_group_id)
    remove_column(:application_settings, :custom_project_templates_group_id)
  end
end
