# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class Logger
      include Gitlab::Utils::StrongMemoize

      def initialize(merge_request:, destination: Gitlab::AppJsonLogger)
        @destination = destination
        @merge_request = merge_request
      end

      def commit
        commit_logs
      end

      def instrument(mergeability_name:)
        raise ArgumentError, 'block not given' unless block_given?

        op_started_at = current_monotonic_time

        result = yield

        observe_result(mergeability_name, result)
        observe("mergeability.#{mergeability_name}.duration_s", current_monotonic_time - op_started_at)

        result
      end

      private

      attr_reader :destination, :merge_request, :stored_result

      def observe_result(name, result)
        observe("mergeability.#{name}.successful", result.success?) if result.respond_to?(:success?)
        observe("mergeability.#{name}.status", result.status.to_s) if result.respond_to?(:status)
      end

      def observe(name, value)
        observations[name.to_s].push(value)
      end

      def commit_logs
        attributes = Gitlab::ApplicationContext.current.merge({ mergeability_project_id: merge_request.project.id })

        attributes[:mergeability_merge_request_id] = merge_request.id
        attributes.merge!(observations_hash)
        attributes.compact!
        attributes.stringify_keys!

        destination.info(attributes)
      end

      def observations_hash
        transformed = observations.transform_values do |values|
          next if values.empty?

          {
            'values' => values
          }
        end.compact

        transformed.each_with_object({}) do |key, hash|
          key[1].each { |k, v| hash["#{key[0]}.#{k}"] = v }
        end
      end

      def observations
        Hash.new { |hash, key| hash[key] = [] }
      end
      strong_memoize_attr :observations

      def current_monotonic_time
        ::Gitlab::Metrics::System.monotonic_time
      end
    end
  end
end
