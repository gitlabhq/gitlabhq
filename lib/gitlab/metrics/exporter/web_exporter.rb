# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        # This exporter is always run on master process
        def initialize
          super

          self.additional_checks = [
            Gitlab::HealthChecks::PumaCheck,
            Gitlab::HealthChecks::UnicornCheck
          ]
        end

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
