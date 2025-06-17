# frozen_string_literal: true

# This concern contains shared functionality for bulk indexing documents in Elasticsearch and OpenSearch databases.

module ActiveContext
  module Databases
    module Concerns
      # Transforms ActiveContext::Query objects into Elasticsearch/Opensearch query DSL format.
      #
      # This processor handles the conversion of various query types into their corresponding
      # Elasticsearch/Opensearch query structures, including:
      # - Term queries for exact matches (single values)
      # - Terms queries for multiple value matches (array values)
      # - Prefix queries for starts-with matches
      # - Bool queries for AND/OR combinations
      # - KNN queries for vector similarity search
      #
      # KNN queries are handled specially to ensure they work with Elasticsearch/Opensearch requirements:
      # - Basic KNN queries are placed at the root level under the 'knn' key
      # - When combining KNN with filters, the filters are included inside the KNN query under 'filter'
      # - OR conditions with KNN maintain the KNN at root level with other conditions under 'query'
      #
      # @example Basic filter query with term
      #   query = ActiveContext::Query.filter(status: 'active')
      #   processor = Processor.new
      #   processor.process(query)
      #   # => { query: { bool: { must: [{ term: { status: 'active' } }] } } }
      #
      # @example Filter query with terms
      #   query = ActiveContext::Query.filter(status: ['active', 'pending'])
      #   processor = Processor.new
      #   processor.process(query)
      #   # => { query: { bool: { must: [{ terms: { status: ['active', 'pending'] } }] } } }
      #
      # @example KNN with filter
      #   query = ActiveContext::Query.filter(status: 'active').knn(
      #     target: 'embedding',
      #     vector: [0.1, 0.2],
      #     k: 5
      #   )
      #   processor = Processor.new
      #   processor.process(query)
      #   # => {
      #   #      knn: {
      #   #        field: 'embedding',
      #   #        query_vector: [0.1, 0.2],
      #   #        k: 5,
      #   #        num_candidates: 50,
      #   #        filter: { bool: { must: [{ term: { status: 'active' } }] } }
      #   #      }
      #   #    }
      module ElasticProcessor
        include ActiveContext::Databases::Concerns::Processor

        def initialize(collection:, user:)
          @collection = collection
          @user = user
        end

        # Processes a query node and returns the corresponding Elasticsearch query
        #
        # @param node [ActiveContext::Query] The query node to process
        # @return [Hash] The Elasticsearch query DSL
        # @raise [ArgumentError] If the query type is not supported
        def process(node)
          case node.type
          when :all     then process_all
          when :filter  then process_filter(node.value)
          when :prefix  then process_prefix(node.value)
          when :or      then process_or(node)
          when :and     then process_and(node.children)
          when :knn     then process_knn(node)
          when :limit   then process_limit(node)
          else
            raise ArgumentError, "Unsupported node type: #{node.type}"
          end
        end

        private

        attr_reader :collection, :user

        def process_all
          { query: { match_all: {} } }
        end

        # Processes filter conditions into term or terms queries
        #
        # @param conditions [Hash] The filter conditions where keys are fields and values are the terms
        # @return [Hash] A bool query with term/terms clauses in the must array
        # @example Single value (term)
        #   process_filter(status: 'active')
        #   # => { query: { bool: { must: [{ term: { status: 'active' } }] } } }
        # @example Array value (terms)
        #   process_filter(status: ['active', 'pending'])
        #   # => { query: { bool: { must: [{ terms: { status: ['active', 'pending'] } }] } } }
        def process_filter(conditions)
          build_bool_query(:must) do |queries|
            conditions.each do |field, value|
              queries << (value.is_a?(Array) ? { terms: { field => value } } : { term: { field => value } })
            end
          end
        end

        # Processes prefix conditions into prefix queries
        #
        # @param conditions [Hash] The prefix conditions where keys are fields and values are the prefixes
        # @return [Hash] A bool query with prefix clauses in the must array
        # @example
        #   process_prefix(name: 'test', path: 'foo/')
        #   # => { query: { bool: { must: [
        #   #      { prefix: { name: 'test' } },
        #   #      { prefix: { path: 'foo/' } }
        #   #    ] } } }
        def process_prefix(conditions)
          build_bool_query(:must) do |queries|
            conditions.each do |field, value|
              queries << { prefix: { field => value } }
            end
          end
        end

        # Processes OR queries, with special handling for KNN
        #
        # @param node [ActiveContext::Query] The OR query node
        # @return [Hash] Either:
        #   - A bool query with should clauses for simple OR conditions
        #   - A combined structure with KNN at root level and other conditions under 'query' for OR with KNN
        # @see #process_simple_or
        # @see #process_or_with_knn
        def process_or(node)
          if contains_knn?(node)
            process_or_with_knn(node)
          else
            process_simple_or(node.children)
          end
        end

        # Processes simple OR conditions (without KNN)
        #
        # @param children [Array<ActiveContext::Query>] The child queries to OR together
        # @return [Hash] A bool query with should clauses and minimum_should_match: 1
        # @example
        #   process_simple_or([filter_query, prefix_query])
        #   # => { query: { bool: {
        #   #      should: [...],
        #   #      minimum_should_match: 1
        #   #    } } }
        def process_simple_or(children)
          build_bool_query(:should, minimum_should_match: 1) do |queries|
            children.each do |child|
              queries << extract_query(process(child))
            end
          end
        end

        # Processes OR conditions that include a KNN query
        def process_or_with_knn(_)
          raise NotImplementedError
        end

        # Processes AND conditions
        #
        # @param children [Array<ActiveContext::Query>] The child queries to AND together
        # @return [Hash] A bool query with must clauses
        # @example
        #   process_and([filter_query, prefix_query])
        #   # => { query: { bool: { must: [...] } } }
        def process_and(children)
          build_bool_query(:must) do |queries|
            children.each do |child|
              queries << extract_query(process(child))
            end
          end
        end

        # Processes KNN query, combining with optional filter conditions
        def process_knn(_)
          raise NotImplementedError
        end

        # Processes limit by adding size parameter
        #
        # @param node [ActiveContext::Query] The limit query node
        # @return [Hash] The query with size parameter added
        # @example
        #   # With size 10:
        #   # => { query: {...}, size: 10 }
        def process_limit(node)
          child_query = process(node.children.first)
          child_query.merge(size: node.value)
        end

        # Checks if node contains a KNN query
        #
        # @param node [ActiveContext::Query] The query node to check
        # @return [Boolean] true if any child is a KNN query
        def contains_knn?(node)
          node.children.any? { |child| child.type == :knn }
        end

        # Finds the KNN child in a query node
        #
        # @param node [ActiveContext::Query] The query node to search
        # @return [ActiveContext::Query, nil] The KNN query node if found
        def find_knn_child(node)
          node.children.find { |child| child.type == :knn }
        end

        # Builds OR conditions excluding KNN query
        #
        # @param node [ActiveContext::Query] The query node to process
        # @param knn_child [ActiveContext::Query] The KNN child to exclude
        # @return [Hash] A bool query with the remaining conditions
        def build_or_conditions(node, knn_child)
          other_queries = node.children.reject { |child| child == knn_child }
          return {} if other_queries.empty?

          build_bool_query(:should, minimum_should_match: 1) do |queries|
            other_queries.each { |child| queries << extract_query(process(child)) }
          end
        end

        # Helper to build bool queries consistently
        #
        # @param type [:must, :should] The bool query type
        # @param minimum_should_match [Integer, nil] Optional minimum matches for should clauses
        # @yield [Array] Yields an array to add query clauses to
        # @return [Hash] The constructed bool query
        def build_bool_query(type, minimum_should_match: nil)
          query = { bool: { type => [] } }
          query[:bool][:minimum_should_match] = minimum_should_match if minimum_should_match

          yield query[:bool][type]

          { query: query }
        end

        # Safely extracts query part from processed result
        #
        # @param processed [Hash] The processed query result
        # @return [Hash] The query part
        def extract_query(processed)
          processed[:query]
        end

        def knn_node_values(node)
          node_values = node.value
          preset_values = collection.current_search_embedding_version

          k = node_values[:k]
          field = node_values[:target] || preset_values[:field]
          vector = node_values[:vector] || get_embeddings(node_values[:content], preset_values[:model])

          {
            k: k,
            field: field,
            vector: vector
          }
        end
      end
    end
  end
end
