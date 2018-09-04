# frozen_string_literal: true

class ImportCommonMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  require_relative '../importers/common_metrics_importer.rb'

  DOWNTIME = false

  def up
    Importers::CommonMetricsImporter.new.execute
  end

  def down
    # no-op
  end
end
