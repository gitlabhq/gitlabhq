# frozen_string_literal: true

# DEPRECATED. Consider using using Internal Events tracking framework
# https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html

require 'rails/generators'

module Gitlab
  module UsageMetricDefinition
    class RedisHllGenerator < Rails::Generators::Base
      desc '[DEPRECATED] Generates a metric definition .yml file with defaults for Redis HLL.'

      argument :category, type: :string, desc: "Category name"
      argument :events, type: :array, desc: "Unique event names", banner: 'event_one event_two event_three'
      class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if metric is for ee'

      def create_metrics
        weekly_key_paths = key_paths.map { |key_path| "#{key_path}_weekly" }
        weekly_params = [*weekly_key_paths, '--dir', '7d', '--class_name', 'RedisHLLMetric']
        weekly_params << '--ee' if ee?
        Gitlab::UsageMetricDefinitionGenerator.start(weekly_params)

        monthly_key_paths = key_paths.map { |key_path| "#{key_path}_monthly" }
        monthly_params = [*monthly_key_paths, '--dir', '28d', '--class_name', 'RedisHLLMetric']
        monthly_params << '--ee' if ee?
        Gitlab::UsageMetricDefinitionGenerator.start(monthly_params)
      end

      private

      def ee?
        options[:ee]
      end

      def key_paths
        events.map { |event| "redis_hll_counters.#{category}.#{event}" }
      end
    end
  end
end
