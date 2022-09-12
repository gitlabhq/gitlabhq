# frozen_string_literal: true

class AddMaxPagesCustomDomainsPerProject < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "app_settings_max_pages_custom_domains_per_project_check"

  def up
    return if column_exists?(:application_settings, :max_pages_custom_domains_per_project)

    add_column :application_settings, :max_pages_custom_domains_per_project, :integer, null: false, default: 0
    add_check_constraint :application_settings, "max_pages_custom_domains_per_project >= 0", CONSTRAINT_NAME
  end

  def down
    return unless column_exists?(:application_settings, :max_pages_custom_domains_per_project)

    remove_column :application_settings, :max_pages_custom_domains_per_project
  end
end
