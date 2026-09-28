# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::Aggregation::AggregationScopeType, feature_category: :value_stream_management do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  describe 'aggregated field complexity' do
    let(:current_user) { build_stubbed(:user) }
    let(:other_user) { build_stubbed(:user) }
    let(:ctx) do
      GraphQL::Query::Context.new(query: query_double(schema: GitlabSchema), values: { current_user: current_user })
    end

    let(:scope_type) { described_class.build(engine, types_prefix: :test) }
    let(:field) { scope_type.fields.fetch('aggregated') }

    subject(:complexity) { field.complexity.call(ctx, arguments, 9) }

    before do
      stub_feature_flags(larger_clickhouse_aggregation_pages: flag_enabled ? current_user : other_user)
    end

    context 'with a ClickHouse engine' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ClickHouse::Engine) }

      where(:flag_enabled, :arguments, :expected_complexity) do
        true  | {}             | 35
        false | {}             | 20
        true  | { first: 250 } | 35
        false | { first: 250 } | 20
        true  | { first: 500 } | 35
        false | { first: 500 } | 20
        true  | { first: 50 }  | 15
        false | { first: 50 }  | 15
        true  | { last: 250 }  | 35
        false | { last: 250 }  | 20
      end

      with_them do
        it 'uses the effective page size for the current user' do
          expect(complexity).to eq(expected_complexity)
        end
      end
    end

    context 'with an engine without its own cap' do
      let(:engine) { Class.new(Gitlab::Database::Aggregation::ActiveRecord::Engine) }
      let(:arguments) { { first: 250 } }

      where(:flag_enabled) { [true, false] }

      with_them do
        it 'uses the schema default cap' do
          expect(complexity).to eq(20)
        end
      end
    end
  end
end
