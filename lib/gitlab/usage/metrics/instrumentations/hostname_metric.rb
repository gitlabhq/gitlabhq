# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class HostnameMetric < GenericMetric
          value do
            Gitlab.config.gitlab.host
          end
        end
      end
    end
  end
end
