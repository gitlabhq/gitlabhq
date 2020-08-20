# frozen_string_literal: true

class AddTextLimitToRunbookOnPrometheusAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :prometheus_alerts, :runbook_url, 255
  end

  def down
    remove_text_limit :prometheus_alerts, :runbook_url
  end
end
