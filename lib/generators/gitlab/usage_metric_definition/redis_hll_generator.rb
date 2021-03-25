# frozen_string_literal: true

require 'rails/generators'
require_relative '../usage_metric_definition_generator'

module Gitlab
  module UsageMetricDefinition
    class RedisHllGenerator < Rails::Generators::Base
      desc 'Generates a metric definition .yml file with defaults for Redis HLL.'

      argument :category, type: :string, desc: "Category name"
      argument :event, type: :string, desc: "Event name"

      def create_metrics
        Gitlab::UsageMetricDefinitionGenerator.start(["#{key_path}_weekly", '--dir', '7d'])
        Gitlab::UsageMetricDefinitionGenerator.start(["#{key_path}_monthly", '--dir', '28d'])
      end

      private

      def key_path
        "redis_hll_counters.#{category}.#{event}"
      end
    end
  end
end
