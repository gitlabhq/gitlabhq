# frozen_string_literal: true

class SetZoektLostNodeThreshold < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '18.1'

  def up
    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = jsonb_set(
        zoekt_settings,
        '{zoekt_lost_node_threshold}',
        '"0"'
      )
      WHERE zoekt_settings ? 'zoekt_auto_delete_lost_nodes'
      AND zoekt_settings->>'zoekt_auto_delete_lost_nodes' = 'false'
    SQL
  end

  def down
    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = jsonb_set(
        zoekt_settings,
        '{zoekt_auto_delete_lost_nodes}',
        'false'
      )
      WHERE zoekt_settings ? 'zoekt_lost_node_threshold'
      AND zoekt_settings->>'zoekt_lost_node_threshold' = '0'
    SQL

    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = jsonb_set(
        zoekt_settings,
        '{zoekt_auto_delete_lost_nodes}',
        'true'
      )
      WHERE zoekt_settings ? 'zoekt_lost_node_threshold'
      AND zoekt_settings->>'zoekt_lost_node_threshold' != '0'
    SQL

    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = zoekt_settings - 'zoekt_lost_node_threshold'
      WHERE zoekt_settings ? 'zoekt_lost_node_threshold'
    SQL
  end
end
