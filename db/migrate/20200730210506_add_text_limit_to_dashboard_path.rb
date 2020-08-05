# frozen_string_literal: true

class AddTextLimitToDashboardPath < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit(:prometheus_metrics, :dashboard_path, 2048)
  end

  def down
    remove_text_limit(:prometheus_metrics, :dashboard_path)
  end
end
