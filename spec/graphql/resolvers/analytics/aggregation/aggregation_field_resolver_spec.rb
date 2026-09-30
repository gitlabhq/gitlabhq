# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::Aggregation::AggregationFieldResolver, feature_category: :value_stream_management do
  describe '.build' do
    let(:response_type) do
      Class.new(Types::BaseObject) do
        graphql_name 'AggregationFieldResolverSpecResponse'
      end
    end

    subject(:resolver) { described_class.build(engine, response_type) }

    context 'with a ClickHouse engine' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ClickHouse::Engine) }

      it 'raises the page size cap' do
        expect(resolver.max_page_size).to eq(500)
      end
    end

    context 'with an engine without its own cap' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ActiveRecord::Engine) }

      it 'keeps the schema default cap' do
        expect(resolver.max_page_size).to be_nil
      end
    end
  end
end
