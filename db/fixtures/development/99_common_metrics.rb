# frozen_string_literal: true

require Rails.root.join('db/importers/common_metrics_importer.rb')

::Importers::CommonMetricsImporter.new.execute
