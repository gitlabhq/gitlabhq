# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::Aggregation::AggregationScopeType, feature_category: :value_stream_management do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  describe 'aggregated field complexity' do
    let(:current_user) { build_stubbed(:user) }
    let(:ctx) do
      GraphQL::Query::Context.new(query: query_double(schema: GitlabSchema), values: { current_user: current_user })
    end

    let(:scope_type) { described_class.build(engine, types_prefix: :test) }
    let(:field) { scope_type.fields.fetch('aggregated') }

    subject(:complexity) { field.complexity.call(ctx, arguments, 9) }

    context 'with a ClickHouse engine' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ClickHouse::Engine) }

      where(:arguments, :expected_complexity) do
        {}              | 60
        { first: 250 }  | 35
        { first: 1000 } | 60
        { first: 50 }   | 15
        { last: 250 }   | 35
      end

      with_them do
        it 'uses the engine page size cap' do
          expect(complexity).to eq(expected_complexity)
        end
      end
    end

    context 'with an engine without its own cap' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ActiveRecord::Engine) }
      let(:arguments) { { first: 250 } }

      it 'uses the schema default cap' do
        expect(complexity).to eq(20)
      end
    end
  end
end
