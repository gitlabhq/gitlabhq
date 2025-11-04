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
end
