# frozen_string_literal: true

class AddCommonToPrometheusMetrics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:prometheus_metrics, :common, :boolean, default: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:prometheus_metrics, :common)
  end
end
