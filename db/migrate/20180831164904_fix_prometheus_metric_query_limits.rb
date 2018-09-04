# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
require Rails.root.join('db/migrate/prometheus_metrics_limits_to_mysql')

class FixPrometheusMetricQueryLimits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    PrometheusMetricsLimitsToMysql.new.up
  end

  def down
    # no-op
  end
end
