# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class McpServerEnabledMetric < GenericMetric
          def value
            ::Gitlab::CurrentSettings.mcp_server_enabled
          end
        end
      end
    end
  end
end
