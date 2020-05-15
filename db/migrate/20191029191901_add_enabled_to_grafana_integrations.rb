# frozen_string_literal: true

class AddEnabledToGrafanaIntegrations < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :grafana_integrations,
      :enabled,
      :boolean,
      allow_null: false,
      default: false
    )
  end

  def down
    remove_column(:grafana_integrations, :enabled)
  end
end
