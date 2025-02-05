# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class WorkerMatcher
      WILDCARD_MATCH = '*'
      QUERY_OR_OPERATOR = '|'
      QUERY_AND_OPERATOR = '&'
      QUERY_CONCATENATE_OPERATOR = ','
      QUERY_TERM_REGEX = %r{^(\w+)(!?=)([\w:#{QUERY_CONCATENATE_OPERATOR}]+)}

      QUERY_PREDICATES = {
        worker_name: :to_s,
        feature_category: :to_sym,
        has_external_dependencies: ->(value) { value == 'true' },
        name: :to_s,
        resource_boundary: :to_sym,
        tags: :to_sym,
        urgency: :to_sym,
        queue_namespace: :to_sym
      }.freeze

      QueryError = Class.new(StandardError)
      InvalidTerm = Class.new(QueryError)
      UnknownOperator = Class.new(QueryError)
      UnknownPredicate = Class.new(QueryError)

      def initialize(query_string)
        @match_lambda = query_string_to_lambda(query_string)
      end

      def match?(worker_metadata)
        @match_lambda.call(worker_metadata)
      end

      private

      def query_string_to_lambda(query_string)
        return ->(_worker) { true } if query_string.strip == WILDCARD_MATCH

        or_clauses = query_string.split(QUERY_OR_OPERATOR).map do |and_clauses_string|
          and_clauses_predicates = and_clauses_string.split(QUERY_AND_OPERATOR).map do |term|
            predicate_for_term(term)
          end

          ->(worker) { and_clauses_predicates.all? { |predicate| predicate.call(worker) } }
        end

        ->(worker) { or_clauses.any? { |predicate| predicate.call(worker) } }
      end

      def predicate_for_term(term)
        match = term.match(QUERY_TERM_REGEX)

        raise InvalidTerm, "Invalid term: #{term}" unless match

        _, lhs, op, rhs = *match

        predicate_for_op(op, predicate_factory(lhs, rhs.split(QUERY_CONCATENATE_OPERATOR)))
      end

      def predicate_for_op(op, predicate)
        case op
        when '='
          predicate
        when '!='
          ->(worker) { !predicate.call(worker) }
        else
          # This is unreachable because InvalidTerm will be raised instead, but
          # keeping it allows to guard against that changing in future.
          raise UnknownOperator, "Unknown operator: #{op}"
        end
      end

      def predicate_factory(lhs, values)
        values_block = QUERY_PREDICATES[lhs.to_sym]

        raise UnknownPredicate, "Unknown predicate: #{lhs}" unless values_block

        ->(queue) do
          comparator = Array(queue[lhs.to_sym]).to_set

          values.map(&values_block).to_set.intersect?(comparator)
        end
      end
    end
  end
end
