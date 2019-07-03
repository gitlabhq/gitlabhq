# frozen_string_literal: true

class AddGrafanaUrlToSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:application_settings, :grafana_url, :string,
                            default: '/-/grafana', allow_null: false)
  end

  def down
    remove_column(:application_settings, :grafana_url)
  end
end
