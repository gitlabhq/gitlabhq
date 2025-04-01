# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Processor
        include Concerns::ElasticProcessor

        # Transforms a query node into Elasticsearch query DSL
        #
        # @param node [ActiveContext::Query] The query node to transform
        # @return [Hash] The Elasticsearch query DSL
        # @example
        #   Processor.transform(ActiveContext::Query.filter(status: 'active'))
        def self.transform(_collection, node)
          new.process(node)
        end

        # Processes KNN query, combining with optional filter conditions
        #
        # @param node [ActiveContext::Query] The KNN query node
        # @return [Hash] KNN parameters at root level, with filter conditions nested inside KNN if present
        # @example
        #   # Basic KNN:
        #   # => { knn: { field: 'embedding', ... } }
        #   # KNN with filter:
        #   # => {
        #   #      knn: {
        #   #        field: 'embedding',
        #   #        ...,
        #   #        filter: { bool: { must: [...] } }
        #   #      }
        #   #    }
        def process_knn(node)
          knn_params = extract_knn_params(node)
          base_query = node.children.any? ? process(node.children.first) : nil
          knn_params[:filter] = extract_query(base_query) if base_query

          { knn: knn_params }
        end

        # Processes OR conditions that include a KNN query
        #
        # @param node [ActiveContext::Query] The OR query node containing KNN
        # @return [Hash] A combined structure with KNN at root level and other conditions under 'query'
        # @example
        #   # For KNN OR filter:
        #   # => {
        #   #      knn: { field: 'embedding', ... },
        #   #      query: { bool: { should: [...], minimum_should_match: 1 } }
        #   #    }
        def process_or_with_knn(node)
          knn_child = find_knn_child(node)
          other_conditions = build_or_conditions(node, knn_child)
          knn_params = extract_knn_params(knn_child)

          other_conditions.empty? ? { knn: knn_params } : { knn: knn_params, query: extract_query(other_conditions) }
        end

        # Extracts KNN parameters from a node into the expected format
        #
        # @param node [ActiveContext::Query] The KNN query node
        # @return [Hash] The formatted KNN parameters
        # @example
        #   # => {
        #   #      field: 'embedding',
        #   #      query_vector: [0.1, 0.2],
        #   #      k: 5,
        #   #      num_candidates: 50
        #   #    }
        def extract_knn_params(node)
          knn_params = node.value
          k = knn_params[:limit]
          {
            field: knn_params[:target],
            query_vector: knn_params[:vector],
            k: k,
            num_candidates: k * 10
          }
        end
      end
    end
  end
end
