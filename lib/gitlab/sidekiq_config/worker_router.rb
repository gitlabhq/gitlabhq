# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class WorkerRouter
      InvalidRoutingRuleError = Class.new(StandardError)
      RuleEvaluator = Struct.new(:matcher, :queue_name)

      def self.queue_name_from_worker_name(worker_klass)
        base_queue_name =
          worker_klass.name
            .delete_prefix('Gitlab::')
            .delete_suffix('Worker')
            .underscore
            .tr('/', '_')
        [worker_klass.queue_namespace, base_queue_name].compact.join(':')
      end

      def self.global
        @global_worker_router ||= new(::Gitlab.config.sidekiq.routing_rules)
      rescue InvalidRoutingRuleError, ::Gitlab::SidekiqConfig::WorkerMatcher::UnknownPredicate => e
        ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

        @global_worker_router = new([])
      end

      # call-seq:
      #   router = WorkerRouter.new([
      #     ["resource_boundary=cpu", 'cpu_boundary'],
      #     ["feature_category=pages", nil],
      #     ["feature_category=source_code_management", ''],
      #     ["*", "default"]
      #   ])
      #   router.route(ACpuBoundaryWorker) # Return "cpu_boundary"
      #   router.route(JustAPagesWorker)   # Return "just_a_pages_worker"
      #   router.route(PostReceive)        # Return "post_receive"
      #   router.route(RandomWorker)       # Return "default"
      #
      # This class is responsible for routing a Sidekiq worker to a certain
      # queue defined in the input routing rules. The input routing rules, as
      # described above, is an order-matter array of tuples [query, queue_name].
      #
      # - The query syntax follows "worker matching query" detailedly
      # denoted in doc/administration/operations/extra_sidekiq_processes.md.
      #
      # - The queue_name must be a valid Sidekiq queue name. If the queue name
      # is nil, or an empty string, the worker is routed to the queue generated
      # by the name of the worker instead.
      #
      # Rules are evaluated from first to last, and as soon as we find a match
      # for a given worker we stop processing for that worker (first match
      # wins). If the worker doesn't match any rule, it falls back the queue
      # name generated from the worker name
      #
      # For further information, please visit:
      #   https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1016
      #
      def initialize(routing_rules)
        @rule_evaluators = parse_routing_rules(routing_rules)
      end

      def route(worker_klass)
        # A medium representation to ensure the backward-compatibility of
        # WorkerMatcher
        worker_metadata = generate_worker_metadata(worker_klass)
        @rule_evaluators.each do |evaluator|
          if evaluator.matcher.match?(worker_metadata)
            return evaluator.queue_name.presence || queue_name_from_worker_name(worker_klass)
          end
        end

        queue_name_from_worker_name(worker_klass)
      end

      private

      def parse_routing_rules(routing_rules)
        raise InvalidRoutingRuleError, 'The set of routing rule must be an array' unless routing_rules.is_a?(Array)

        routing_rules.map do |rule_tuple|
          raise InvalidRoutingRuleError, "Routing rule `#{rule_tuple.inspect}` is invalid" unless valid_routing_rule?(rule_tuple)

          selector, destination_queue = rule_tuple
          RuleEvaluator.new(
            ::Gitlab::SidekiqConfig::WorkerMatcher.new(selector),
            destination_queue
          )
        end
      end

      def valid_routing_rule?(rule_tuple)
        rule_tuple.is_a?(Array) && rule_tuple.length == 2
      end

      def generate_worker_metadata(worker_klass)
        # The ee indicator here is insignificant and irrelevant to the matcher.
        # Plus, it's not easy to determine whether a worker is **only**
        # available in EE.
        ::Gitlab::SidekiqConfig::Worker.new(worker_klass, ee: false).to_yaml
      end

      def queue_name_from_worker_name(worker_klass)
        self.class.queue_name_from_worker_name(worker_klass)
      end
    end
  end
end
