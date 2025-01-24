# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      # Transforms ActiveContext::Query objects into Elasticsearch query DSL format.
      #
      # This processor handles the conversion of various query types into their corresponding
      # Elasticsearch query structures, including:
      # - Term queries for exact matches (single values)
      # - Terms queries for multiple value matches (array values)
      # - Prefix queries for starts-with matches
      # - Bool queries for AND/OR combinations
      # - KNN queries for vector similarity search
      #
      # KNN queries are handled specially to ensure they work with Elasticsearch's requirements:
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
      #     limit: 5
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
      class Processor
        include ActiveContext::Databases::Concerns::Processor

        # Transforms a query node into Elasticsearch query DSL
        #
        # @param node [ActiveContext::Query] The query node to transform
        # @return [Hash] The Elasticsearch query DSL
        # @example
        #   Processor.transform(ActiveContext::Query.filter(status: 'active'))
        def self.transform(node)
          new.process(node)
        end

        # Processes a query node and returns the corresponding Elasticsearch query
        #
        # @param node [ActiveContext::Query] The query node to process
        # @return [Hash] The Elasticsearch query DSL
        # @raise [ArgumentError] If the query type is not supported
        def process(node)
          case node.type
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
