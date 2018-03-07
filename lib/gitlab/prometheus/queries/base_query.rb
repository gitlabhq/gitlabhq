module Gitlab
  module Prometheus
    module Queries
      class BaseQuery
        attr_accessor :client
        delegate :query_range, :query, :label_values, :series, to: :client, prefix: true

        def raw_memory_usage_query(environment_slug)
          %{avg(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"}) / 2^20}
        end

        def raw_cpu_usage_query(environment_slug)
          %{avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}[2m])) * 100}
        end

        def initialize(client)
          @client = client
        end

        def query(*args)
          raise NotImplementedError
        end

        def self.transform_reactive_result(result)
          result
        end
      end
    end
  end
end
