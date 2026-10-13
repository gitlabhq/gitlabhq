# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::Aggregation::EngineResolver, :aggregate_failures, feature_category: :value_stream_management do
  let(:engine_class) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.metrics_mapping
        { metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition }
      end

      def self.dimensions_mapping
        { column: Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition }
      end

      def self.filters_mapping
        {
          exact_match: Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter,
          metric_range: Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter
        }
      end

      dimensions do
        column :user_id, :integer
      end

      metrics do
        metric :total, :integer, description: 'Total count'
      end

      filters do
        exact_match :status, :string, description: 'Filter by status'
        metric_range :total, :integer, description: 'Filter by total'
      end
    end
  end

  describe '.build' do
    # The mount block is the one route by which an experiment argument lands on the
    # generated resolver, so declare one here.
    subject(:resolver) do
      described_class.build(engine_class, types_prefix: :pipelines) do
        argument :experimental_filter, GraphQL::Types::String,
          required: false,
          description: 'Experimental filter.',
          experiment: { milestone: '19.5' }
      end
    end

    let(:inner_resolver) { resolver.type.unwrap.fields['aggregated'].resolver }

    it 'names the generated resolvers after the types prefix' do
      expect(resolver.graphql_name).to eq('PipelinesAggregationResolver')
      expect(inner_resolver.graphql_name).to eq('PipelinesAggregationFieldResolver')
    end

    # graphql-ruby's FieldUsage analyzer reads `Argument#path` for every deprecated
    # argument, which raised on the unnamed anonymous owner.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/630513
    it 'resolves a path for generated and experiment arguments' do
      expect(resolver.get_argument('status').path).to eq('PipelinesAggregationResolver.status')
      expect(inner_resolver.get_argument('totalFrom').path).to eq('PipelinesAggregationFieldResolver.totalFrom')

      experimental = resolver.get_argument('experimentalFilter')
      expect(experimental.deprecation_reason).to be_present
      expect(experimental.path).to eq('PipelinesAggregationResolver.experimentalFilter')
    end
  end
end
