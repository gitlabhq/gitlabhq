# frozen_string_literal: true

# Represents a flexible and composable query builder for constructing complex search and filtering queries.
#
# The Query class provides a fluent, chainable interface for building queries with various types
# of conditions and logical operations. It supports filter, prefix, limit, k-nearest neighbor (KNN),
# and logical AND/OR operations.
#
# @example Simple filter query
#   ActiveContext::Query.filter(project_id: 1)
#
# @example Compound query with OR and limit
#   ActiveContext::Query.or(
#     ActiveContext::Query.filter(project_id: 1),
#     ActiveContext::Query.prefix(traversal_ids: 1)
#   ).limit(5)
#
# @example Nested OR query with multiple conditions
#   ActiveContext::Query.filter(hello: :foo)
#     .or(
#       ActiveContext::Query.filter(project_id: 1),
#       ActiveContext::Query.prefix(traversal_ids: '9970-')
#     )
#
# @example KNN vector search
#   ActiveContext::Query.knn(target: "similarity", vector: [0.1, 0.2, 0.3], limit: 5)
#
# Supported Query Types:
# - :filter   - Exact match conditions
# - :prefix   - Prefix/starts-with conditions
# - :limit    - Restricts number of results
# - :knn      - K-nearest neighbor vector search
# - :and      - Logical AND between queries
# - :or       - Logical OR between queries
#
# Key Features:
# - Immutable query construction
# - Type safety with explicit argument validation
# - Chainable method calls for complex query composition
# - Debugging support via #inspect_ast method
#
# @note Queries are immutable; each method call returns a new Query instance
# @note Raises ArgumentError for invalid or empty query configurations

module ActiveContext
  class Query
    ALLOWED_TYPES = [:filter, :prefix, :limit, :knn, :and, :or].freeze
    SPACES_PER_INDENT = 2

    class << self
      # Class methods to start the chain
      def filter(**conditions)
        raise ArgumentError, "Filter cannot be empty" if conditions.empty?

        new(type: :filter, value: conditions)
      end

      def prefix(**conditions)
        raise ArgumentError, "Prefix cannot be empty" if conditions.empty?

        new(type: :prefix, value: conditions)
      end

      def or(*queries)
        raise ArgumentError, "Or cannot be empty" if queries.empty?

        new(type: :or, children: queries)
      end

      def and(*queries)
        raise ArgumentError, "And cannot be empty" if queries.empty?

        new(type: :and, children: queries)
      end

      def knn(target:, vector:, limit:)
        new(type: :knn, value: validate_and_build_knn_params(target: target, vector: vector, limit: limit))
      end

      def validate_and_build_knn_params(target:, vector:, limit:)
        raise ArgumentError, "Target cannot be nil" if target.nil?
        raise ArgumentError, "Vector must be an array" unless vector.is_a?(Array)

        if !limit.is_a?(Integer) || limit <= 0
          raise ArgumentError, "Limit must be a positive number, you used #{limit.class}: #{limit}"
        end

        {
          target: target,
          vector: vector,
          limit: limit
        }.compact
      end
    end

    attr_reader :type, :value, :children

    def initialize(type:, value: nil, children: [])
      unless ALLOWED_TYPES.include?(type)
        raise ArgumentError, "Invalid type: #{type}. Allowed types are: #{ALLOWED_TYPES.join(', ')}"
      end

      @type = type
      @value = value
      @children = children
    end

    def or(*other_queries)
      raise ArgumentError, "Or cannot be empty" if other_queries.empty?

      self.class.new(type: :and, children: [
        self,
        self.class.new(type: :or, children: other_queries)
      ])
    end

    def and(*other_queries)
      raise ArgumentError, "And cannot be empty" if other_queries.empty?

      self.class.new(type: :and, children: [self, *other_queries])
    end

    def limit(count)
      raise ArgumentError, 'Limit cannot be empty' if count.nil?
      raise ArgumentError, "Limit must be a number, you used #{count.class}: #{count}" unless count.is_a?(Integer)

      self.class.new(type: :limit, value: count, children: [self])
    end

    def knn(target:, vector:, limit:)
      self.class.new(
        type: :knn,
        value: self.class.validate_and_build_knn_params(target: target, vector: vector, limit: limit),
        children: [self]
      )
    end

    def inspect_ast(indent = 0)
      indentation = " " * SPACES_PER_INDENT * indent
      details = case type
                when :filter, :prefix
                  "#{type}(#{value.map { |k, v| "#{k}: #{v}" }.join(', ')})"
                when :knn
                  knn_details = ["target: #{value[:target]}", "vector: [#{value[:vector].join(', ')}]"]
                  knn_details << "limit: #{value[:limit]}" if value[:limit]
                  "knn(#{knn_details.join(', ')})"
                when :limit
                  "#{type}(#{value})"
                else
                  type.to_s
                end

      children_output = children.map { |child| child.inspect_ast(indent + 1) }.join("\n")
      if children_output.empty?
        "#{indentation}#{details}"
      else
        "#{indentation}#{details}\n#{children_output}"
      end
    end
  end
end
