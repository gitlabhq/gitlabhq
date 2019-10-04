# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        def settings
          Settings.monitoring.web_exporter
        end

        def log_filename
          File.join(Rails.root, 'log', 'web_exporter.log')
        end
      end
    end
  end
end
