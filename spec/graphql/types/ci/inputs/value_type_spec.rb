# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInputsValue'], feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiInputsValue') }

  describe '.coerce_input' do
    subject(:coerce_input) { described_class.coerce_isolated_input(value) }

    context 'on valid values' do
      using RSpec::Parameterized::TableSyntax

      where(:value, :result) do
        'foo'  | 'foo'
        1      | 1
        [1, 2] | [1, 2]
        true   | true
        false  | false
        nil    | nil
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'on invalid values' do
      let(:value) { { foo: :bar } }

      it { expect { coerce_input }.to raise_error(GraphQL::CoercionError) }
    end
  end
end
