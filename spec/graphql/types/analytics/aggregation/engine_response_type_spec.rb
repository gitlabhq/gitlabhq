# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::Aggregation::EngineResponseType, feature_category: :database do
  let(:engine_class) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.metrics_mapping
        {
          metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition,
          quantile: Gitlab::Database::Aggregation::ClickHouse::Quantile
        }
      end

      def self.dimensions_mapping
        { column: Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition }
      end

      def self.filters_mapping
        {}
      end

      dimensions do
        column :user_id, :integer
      end

      metrics do
        metric :total, :integer, description: 'Total count'
        metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') }, description: 'Maximum duration'
        metric :"duration.mean", :float, ->(_params) { Arel.sql('avg(duration)') }, description: 'Mean duration'
        quantile :"duration.quantile", :float, ->(_params) { Arel.sql('duration') },
          description: 'Duration quantile',
          parameters: { quantile: { type: :float, description: 'Quantile to calculate' } }
      end
    end
  end

  let(:response_type) { described_class.build(engine_class, { types_prefix: :test }) }

  it 'declares flat metrics and dimensions as top-level fields' do
    expect(response_type.fields.keys).to contain_exactly('dimensions', 'total', 'duration')
  end

  describe 'metric group field' do
    let(:group_field) { response_type.fields['duration'] }
    let(:group_type) { group_field.type }

    it 'nests dotted metrics under a group field' do
      expect(group_type.graphql_name).to eq('TestAggregationResponseDurationMetrics')
      expect(group_type.fields.keys).to contain_exactly('max', 'mean', 'quantile')
    end

    it 'derives sub-field types from the metric definitions' do
      expect(group_type.fields['max'].type).to eq(GraphQL::Types::Int)
      expect(group_type.fields['mean'].type).to eq(GraphQL::Types::Float)
      expect(group_type.fields['quantile'].type).to eq(GraphQL::Types::Float)
    end

    it 'declares metric parameters as sub-field arguments' do
      expect(group_type.fields['quantile'].arguments.keys).to contain_exactly('quantile')
    end

    it 'resolves the group field to the row object itself' do
      expect(group_field.resolver_method).to eq(:object)
    end

    it 'resolves sub-field values from sanitized instance keys' do
      row = { 'duration__max' => 42, 'duration__mean' => 21.5 }
      group_instance = group_type.allocate
      allow(group_instance).to receive(:object).and_return(row)

      expect(group_instance.max).to eq(42)
      expect(group_instance.mean).to eq(21.5)
    end
  end
end
