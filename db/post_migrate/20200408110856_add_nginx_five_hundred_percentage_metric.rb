# frozen_string_literal: true

class AddNginxFiveHundredPercentageMetric < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
  end
end
