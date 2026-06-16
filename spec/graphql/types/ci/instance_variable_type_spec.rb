# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInstanceVariable'], feature_category: :pipeline_composition do
  include GraphqlHelpers

  specify { expect(described_class.interfaces).to contain_exactly(Types::Ci::VariableInterface) }

  specify do
    expect(described_class).to have_graphql_fields(
      :environment_scope, :hidden, :masked, :protected, :description
    ).at_least
  end

  describe '#value' do
    subject(:resolved_value) { resolve_field(:value, variable, object_type: described_class) }

    context 'when the variable is not hidden' do
      let(:variable) do
        create(:ci_instance_variable, key: 'TEST_KEY', value: 'test_value',
          masked: false, hidden: false)
      end

      it 'returns the value' do
        expect(resolved_value).to eq('test_value')
      end
    end

    context 'when the variable is hidden' do
      let(:variable) do
        create(:ci_instance_variable, key: 'HIDDEN_KEY', value: 'secret_value',
          masked: true, hidden: true)
      end

      it 'returns nil' do
        expect(resolved_value).to be_nil
      end
    end
  end
end
