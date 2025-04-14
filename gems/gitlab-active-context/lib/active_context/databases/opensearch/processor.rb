# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Processor
        include Concerns::ElasticProcessor

        # Transforms a query node into Opensearch query DSL
        #
        # @param node [ActiveContext::Query] The query node to transform
        # @return [Hash] The Opensearch query DSL
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

          query = build_bool_query(:should) do |queries|
            queries << { knn: knn_params }
          end

          base_query = node.children.any? ? process(node.children.first) : nil

          if base_query
            filter = extract_query(base_query)
            query[:query][:bool][:must] = filter[:bool][:must]
          end

          query
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
          query = build_or_conditions(node, knn_child)
          knn_query = { knn: extract_knn_params(knn_child) }

          if query.empty?
            build_bool_query(:should) do |queries|
              queries << knn_query
            end
          else
            query[:query][:bool][:should] << knn_query
            query
          end
        end

        # Extracts KNN parameters from a node into the expected format
        #
        # @param node [ActiveContext::Query] The KNN query node
        # @return [Hash] The formatted KNN parameters
        # @example
        #   # => {
        #   #      'embedding': {
        #   #        vector: [0.1, 0.2],
        #   #        k: 5
        #   #      }
        #   #    }
        def extract_knn_params(node)
          knn_params = node.value
          k = knn_params[:limit]

          {
            knn_params[:target] => {
              k: k,
              vector: knn_params[:vector]
            }
          }
        end
      end
    end
  end
end
