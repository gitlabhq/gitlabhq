# frozen_string_literal: true

class AddInactiveProjectDeletionToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :delete_inactive_projects, :boolean, default: false, null: false
    add_column :application_settings, :inactive_projects_delete_after_months, :integer, default: 2, null: false
    add_column :application_settings, :inactive_projects_min_size_mb, :integer, default: 0, null: false
    add_column :application_settings, :inactive_projects_send_warning_email_after_months,
      :integer, default: 1, null: false
  end
end
