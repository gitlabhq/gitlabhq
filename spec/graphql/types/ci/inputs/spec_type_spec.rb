# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Inputs::SpecType, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let(:current_user) { nil }

  specify { expect(described_class.graphql_name).to eq('CiInputsSpec') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      type
      description
      required
      default
      options
      regex
      rules
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#rules' do
    let(:input) { Ci::Inputs::StringInput.new(name: 'test_input', spec: spec) }
    let(:spec_type) { described_class.authorized_new(input, query_context) }

    context 'when rules are present' do
      let(:spec) do
        {
          type: 'string',
          rules: [
            {
              'if' => '$[[ inputs.environment ]] == "production"',
              'options' => %w[opt1 opt2]
            }
          ]
        }
      end

      it 'returns the rules' do
        rules = spec_type.rules

        expect(rules).to be_an(Array)
        expect(rules.size).to eq(1)
        expect(rules.first['if']).to eq('$[[ inputs.environment ]] == "production"')
        expect(rules.first['options']).to eq(%w[opt1 opt2])
      end
    end

    context 'when rules are not present' do
      let(:spec) do
        {
          type: 'string',
          default: 'value'
        }
      end

      it 'returns nil' do
        expect(spec_type.rules).to be_nil
      end
    end
  end
end
