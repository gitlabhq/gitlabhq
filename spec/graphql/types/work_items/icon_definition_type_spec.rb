# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::IconDefinitionType, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItemTypeIconDefinition') }

  it 'has expected fields' do
    expected_fields = %i[name label]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
