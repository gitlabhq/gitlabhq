# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  module UsageMetricDefinition
    class RedisHllGenerator < Rails::Generators::Base
      desc 'Generates a metric definition .yml file with defaults for Redis HLL.'

      argument :category, type: :string, desc: "Category name"
      argument :event, type: :string, desc: "Event name"
      class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if metric is for ee'

      def create_metrics
        weekly_params = ["#{key_path}_weekly", '--dir', '7d']
        weekly_params << '--ee' if ee?
        Gitlab::UsageMetricDefinitionGenerator.start(weekly_params)

        monthly_params = ["#{key_path}_monthly", '--dir', '28d']
        monthly_params << '--ee' if ee?
        Gitlab::UsageMetricDefinitionGenerator.start(monthly_params)
      end

      private

      def ee?
        options[:ee]
      end

      def key_path
        "redis_hll_counters.#{category}.#{event}"
      end
    end
  end
end
