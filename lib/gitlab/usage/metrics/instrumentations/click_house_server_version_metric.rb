# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ClickHouseServerVersionMetric < GenericMetric
          value do
            ::ClickHouse::Connection.new(:main).version if ::ClickHouse::Client.database_configured?(:main)
          end
        end
      end
    end
  end
end
