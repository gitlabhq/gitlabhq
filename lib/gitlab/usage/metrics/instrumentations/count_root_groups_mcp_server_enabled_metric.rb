# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountRootGroupsMcpServerEnabledMetric < DatabaseMetric
          operation :count

          relation { ::Group }
          start { ::Group.minimum(:id) }
          finish { ::Group.maximum(:id) }
          metric_options { { batch_size: 10_000 } }

          def initialize(metric_definition)
            super

            return if options[:mcp_server_enabled].in?([true, false])

            raise ArgumentError, "Unknown parameters: mcp_server_enabled:#{options[:mcp_server_enabled]}"
          end

          private

          def relation
            super.top_level.joins(:namespace_settings)
              .where(namespace_settings: { mcp_server_enabled: options[:mcp_server_enabled] })
          end
        end
      end
    end
  end
end
