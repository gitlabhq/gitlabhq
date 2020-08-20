# frozen_string_literal: true

class ImportLatestCommonMetrics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # The common_metrics queries were updated to work with K8s versions that
    # use the pod/container label names as well as K8s versions that use the
    # older pod_name/container_name convention.
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
    # The import cannot be reversed since we do not know the state that the
    # common metrics in the PrometheusMetric table were in before the import.

    # To manually revert this migration.
    # 1. Go back to the previous version of the config/prometheus/common_metrics.yml file. (git checkout 74447f11349617ed8b273196d6a5781d9a67a613)
    # 2. Execute `rails runner '::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute'`
  end
end
