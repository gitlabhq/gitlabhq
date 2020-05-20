# frozen_string_literal: true

class ChangeVariableInterpolationFormatInCommonMetrics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
    # The import cannot be reversed since we do not know the state that the
    # common metrics in the PrometheusMetric table were in before the import.
  end
end
