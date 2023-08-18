# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::LinkedItemType, feature_category: :portfolio_management do
  specify { expect(described_class.graphql_name).to eq('LinkedWorkItemType') }

  it 'exposes the expected fields' do
    expected_fields = %i[linkCreatedAt linkId linkType linkUpdatedAt workItem]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
