module Gitlab
  module Prometheus
    module Queries
      class ValidateQuery < BaseQuery
        def query(query)
          client_query(query)
          { valid: true }
        rescue Gitlab::PrometheusClient::QueryError => ex
          { valid: false, error: ex.message }
        end
      end
    end
  end
end
