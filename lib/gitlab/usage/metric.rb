# frozen_string_literal: true

module Gitlab
  module Usage
    class Metric
      include ActiveModel::Model

      InvalidMetricError = Class.new(RuntimeError)

      attr_accessor :default_generation_path, :value

      validates :default_generation_path, presence: true

      def definition
        self.class.definitions[default_generation_path]
      end

      def unflatten_default_path
        unflatten(default_generation_path.split('.'), value)
      end

      class << self
        def definitions
          @definitions ||= Gitlab::Usage::MetricDefinition.definitions
        end

        def dictionary
          definitions.map { |key, definition| definition.to_dictionary }
        end
      end

      private

      def unflatten(keys, value)
        loop do
          value = { keys.pop.to_sym => value }
          break if keys.blank?
        end
        value
      end
    end
  end
end
