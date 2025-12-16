# frozen_string_literal: true

class RemoveZoektMinimumProjectsForTraversalIdSearchFromApplicationSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting
  milestone '18.7'

  def up
    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = zoekt_settings - 'zoekt_minimum_projects_for_traversal_id_search'
      WHERE zoekt_settings ? 'zoekt_minimum_projects_for_traversal_id_search'
    SQL
  end

  def down
    # This migration removes a deprecated setting that is no longer used.
    # Rollback is not supported as the setting value cannot be recovered.
  end
end
