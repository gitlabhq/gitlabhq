# frozen_string_literal: true

module Gitlab
  module Elasticsearch
    module Logs
      class Pods
        # How many items to fetch in a query
        PODS_LIMIT = 500
        CONTAINERS_LIMIT = 500

        def initialize(client)
          @client = client
        end

        def pods(namespace)
          body = build_body(namespace)
          response = @client.search body: body

          format_response(response)
        end

        private

        def build_body(namespace)
          {
            aggs: {
              pods: {
                aggs: {
                  containers: {
                    terms: {
                      field: 'kubernetes.container.name',
                      size: ::Gitlab::Elasticsearch::Logs::Pods::CONTAINERS_LIMIT
                    }
                  }
                },
                terms: {
                  field: 'kubernetes.pod.name',
                  size: ::Gitlab::Elasticsearch::Logs::Pods::PODS_LIMIT
                }
              }
            },
            query: {
              bool: {
                must: {
                  match_phrase: {
                    "kubernetes.namespace": namespace
                  }
                }
              }
            },
            # don't populate hits, only the aggregation is needed
            size: 0
          }
        end

        def format_response(response)
          results = response.dig("aggregations", "pods", "buckets") || []
          results.map do |bucket|
            {
              name: bucket["key"],
              container_names: (bucket.dig("containers", "buckets") || []).map do |cbucket|
                cbucket["key"]
              end
            }
          end
        end
      end
    end
  end
end
