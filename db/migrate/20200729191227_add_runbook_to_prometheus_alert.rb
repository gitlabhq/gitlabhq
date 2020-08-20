# frozen_string_literal: true

class AddRunbookToPrometheusAlert < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # limit is added in 20200501000002_add_text_limit_to_sprints_extended_title
    add_column :prometheus_alerts, :runbook_url, :text # rubocop:disable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :prometheus_alerts, :runbook_url
  end
end
