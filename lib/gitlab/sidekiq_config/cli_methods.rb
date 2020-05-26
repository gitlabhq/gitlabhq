# frozen_string_literal: true

require 'yaml'
require 'set'

# These methods are called by `sidekiq-cluster`, which runs outside of
# the bundler/Rails context, so we cannot use any gem or Rails methods.
module Gitlab
  module SidekiqConfig
    module CliMethods
      # The methods in this module are used as module methods
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      extend self

      QUEUE_CONFIG_PATHS = begin
        result = %w[app/workers/all_queues.yml]
        result << 'ee/app/workers/all_queues.yml' if Gitlab.ee?
        result
      end.freeze

      QUERY_OR_OPERATOR = '|'
      QUERY_AND_OPERATOR = '&'
      QUERY_CONCATENATE_OPERATOR = ','
      QUERY_TERM_REGEX = %r{^(\w+)(!?=)([\w:#{QUERY_CONCATENATE_OPERATOR}]+)}.freeze

      QUERY_PREDICATES = {
        feature_category: :to_sym,
        has_external_dependencies: lambda { |value| value == 'true' },
        name: :to_s,
        resource_boundary: :to_sym,
        tags: :to_sym,
        urgency: :to_sym
      }.freeze

      QueryError = Class.new(StandardError)
      InvalidTerm = Class.new(QueryError)
      UnknownOperator = Class.new(QueryError)
      UnknownPredicate = Class.new(QueryError)

      def all_queues(rails_path = Rails.root.to_s)
        @worker_queues ||= {}

        @worker_queues[rails_path] ||= QUEUE_CONFIG_PATHS.flat_map do |path|
          full_path = File.join(rails_path, path)

          File.exist?(full_path) ? YAML.load_file(full_path) : []
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def worker_queues(rails_path = Rails.root.to_s)
        worker_names(all_queues(rails_path))
      end

      def expand_queues(queues, all_queues = self.worker_queues)
        return [] if queues.empty?

        queues_set = all_queues.to_set

        queues.flat_map do |queue|
          [queue, *queues_set.grep(/\A#{queue}:/)]
        end
      end

      def query_workers(query_string, queues)
        worker_names(queues.select(&query_string_to_lambda(query_string)))
      end

      def clear_memoization!
        if instance_variable_defined?('@worker_queues')
          remove_instance_variable('@worker_queues')
        end
      end

      private

      def worker_names(workers)
        workers.map { |queue| queue[:name] }
      end

      def query_string_to_lambda(query_string)
        or_clauses = query_string.split(QUERY_OR_OPERATOR).map do |and_clauses_string|
          and_clauses_predicates = and_clauses_string.split(QUERY_AND_OPERATOR).map do |term|
            predicate_for_term(term)
          end

          lambda { |worker| and_clauses_predicates.all? { |predicate| predicate.call(worker) } }
        end

        lambda { |worker| or_clauses.any? { |predicate| predicate.call(worker) } }
      end

      def predicate_for_term(term)
        match = term.match(QUERY_TERM_REGEX)

        raise InvalidTerm.new("Invalid term: #{term}") unless match

        _, lhs, op, rhs = *match

        predicate_for_op(op, predicate_factory(lhs, rhs.split(QUERY_CONCATENATE_OPERATOR)))
      end

      def predicate_for_op(op, predicate)
        case op
        when '='
          predicate
        when '!='
          lambda { |worker| !predicate.call(worker) }
        else
          # This is unreachable because InvalidTerm will be raised instead, but
          # keeping it allows to guard against that changing in future.
          raise UnknownOperator.new("Unknown operator: #{op}")
        end
      end

      def predicate_factory(lhs, values)
        values_block = QUERY_PREDICATES[lhs.to_sym]

        raise UnknownPredicate.new("Unknown predicate: #{lhs}") unless values_block

        lambda do |queue|
          comparator = Array(queue[lhs.to_sym]).to_set

          values.map(&values_block).to_set.intersect?(comparator)
        end
      end
    end
  end
end
