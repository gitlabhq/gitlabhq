# frozen_string_literal: true

class AddPagesUniqueDomainColumnsToProjectSettings < Gitlab::Database::Migration[2.1]
  def up
    add_column :project_settings, :pages_unique_domain_enabled, :boolean, default: false, null: false
    add_column :project_settings, :pages_unique_domain, :text # rubocop: disable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :project_settings, :pages_unique_domain_enabled, :boolean
    remove_column :project_settings, :pages_unique_domain, :text
  end
end
