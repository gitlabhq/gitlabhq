# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::Aggregation::AggregationFieldResolver::BaseAggregationFieldResolver,
  feature_category: :database do
  describe '#build_metric_parts' do
    let(:engine_class) do
      Gitlab::Database::Aggregation::Engine.build do
        def self.metrics_mapping
          { metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition }
        end

        def self.dimensions_mapping
          {}
        end

        def self.filters_mapping
          {}
        end

        metrics do
          metric :total, :integer
          metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') }
          metric :"duration.quantile", :float, ->(_params) { Arel.sql('duration') },
            parameters: { quantile: { type: :float } }
        end
      end
    end

    let(:engine) { engine_class.new(context: {}) }
    let(:resolver) { described_class.new(object: nil, context: double.as_null_object, field: nil) }

    def selection(name, arguments: {}, selections: [])
      instance_double(GraphQL::Execution::Lookahead, name: name, arguments: arguments, selections: selections)
    end

    it 'builds flat metric parts from top-level selections' do
      parts = resolver.send(:build_metric_parts, [selection(:total)], engine)

      expect(parts).to eq([{ identifier: :total, parameters: {} }])
    end

    it 'expands metric group selections into dotted identifiers' do
      group = selection(:duration, selections: [
        selection(:max),
        selection(:quantile, arguments: { quantile: 0.9 })
      ])

      parts = resolver.send(:build_metric_parts, [selection(:total), group], engine)

      expect(parts).to eq([
        { identifier: :total, parameters: {} },
        { identifier: :"duration.max", parameters: {} },
        { identifier: :"duration.quantile", parameters: { quantile: 0.9 } }
      ])
    end

    it 'ignores introspection selections inside groups' do
      group = selection(:duration, selections: [selection(:__typename), selection(:max)])

      parts = resolver.send(:build_metric_parts, [group], engine)

      expect(parts).to eq([{ identifier: :"duration.max", parameters: {} }])
    end
  end
end
