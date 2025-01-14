# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::LinkedItemType, feature_category: :portfolio_management do
  specify { expect(described_class.graphql_name).to eq('LinkedWorkItemType') }

  it 'exposes the expected fields' do
    expected_fields = %i[linkCreatedAt linkId linkType linkUpdatedAt workItem workItemState]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'work_item' do
    subject { described_class.fields['workItem'] }

    it { is_expected.to have_nullable_graphql_type(Types::WorkItemType) }
  end
end
