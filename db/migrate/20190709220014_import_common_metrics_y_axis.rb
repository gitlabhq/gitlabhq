# frozen_string_literal: true

class ImportCommonMetricsYAxis < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def up
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
  end
end
