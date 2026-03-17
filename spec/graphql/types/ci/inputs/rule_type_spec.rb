# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Inputs::RuleType, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let(:current_user) { nil }

  specify { expect(described_class.graphql_name).to eq('CiInputsRule') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      condition_tree
      default
      if
      options
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#condition_tree' do
    let(:rule) { described_class.authorized_new(rule_hash, query_context) }

    context 'with a valid if clause' do
      let(:rule_hash) do
        {
          'if' => '$[[ inputs.environment ]] == "production"',
          'options' => %w[opt1 opt2]
        }
      end

      it 'returns a parsed condition tree' do
        result = rule.condition_tree

        expect(result).to be_a(Hash)
        expect(result['operator']).to eq('equals')
        expect(result['field']).to eq('environment')
        expect(result['value']).to eq('production')
      end
    end

    context 'with a complex nested expression' do
      let(:rule_hash) do
        {
          'if' => '$[[ inputs.env ]] == "prod" && $[[ inputs.region ]] == "us"',
          'options' => ['opt1']
        }
      end

      it 'returns a nested condition tree' do
        result = rule.condition_tree

        expect(result).to be_a(Hash)
        expect(result['operator']).to eq('AND')
        expect(result['children']).to be_an(Array)
        expect(result['children'].size).to eq(2)
      end
    end

    context 'without an if clause' do
      let(:rule_hash) do
        {
          'default' => 'value'
        }
      end

      it 'returns nil' do
        expect(rule.condition_tree).to be_nil
      end
    end

    context 'with an invalid expression' do
      let(:rule_hash) do
        {
          'if' => '&&&&'
        }
      end

      it 'raises an execution error' do
        expect { rule.condition_tree }.to raise_error(GraphQL::ExecutionError, /Invalid expression in rule/)
      end
    end
  end

  describe 'numeric values in options and default' do
    let(:rule) { described_class.authorized_new(rule_hash, query_context) }

    context 'with numeric options' do
      let(:rule_hash) do
        {
          'if' => '$[[ inputs.env ]] == "prod"',
          'options' => [1, 50, 100],
          'default' => 50
        }
      end

      it 'preserves numeric types in options array' do
        expect(rule_hash['options']).to match_array([1, 50, 100])
        expect(rule_hash['options']).to all(be_a(Integer))
      end

      it 'preserves numeric type in default value' do
        expect(rule_hash['default']).to eq(50)
        expect(rule_hash['default']).to be_a(Integer)
      end
    end

    context 'with mixed type options' do
      let(:rule_hash) do
        {
          'if' => '$[[ inputs.env ]] == "prod"',
          'options' => [1, 'string', true, nil],
          'default' => 'string'
        }
      end

      it 'preserves all value types in options array' do
        expect(rule_hash['options']).to match_array([1, 'string', true, nil])
        expect(rule_hash['options'][0]).to be_a(Integer)
        expect(rule_hash['options'][1]).to be_a(String)
        expect(rule_hash['options'][2]).to be(true)
        expect(rule_hash['options'][3]).to be_nil
      end
    end
  end
end
