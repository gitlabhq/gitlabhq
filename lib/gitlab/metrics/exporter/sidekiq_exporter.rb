# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class SidekiqExporter < BaseExporter
        def settings
          Settings.monitoring.sidekiq_exporter
        end

        def log_filename
          File.join(Rails.root, 'log', 'sidekiq_exporter.log')
        end
      end
    end
  end
end
