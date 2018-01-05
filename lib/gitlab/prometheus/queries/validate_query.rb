module Gitlab
  module Prometheus
    module Queries
      class ValidateQuery < BaseQuery
        def query(query)
          client_query_range(query, start: 1.second.ago.to_f)
          { valid: true }
        rescue Gitlab::PrometheusQueryError => ex
          { valid: false, error: ex.message }
        end
      end
    end
  end
end
