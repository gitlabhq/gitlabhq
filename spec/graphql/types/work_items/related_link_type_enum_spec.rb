# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::RelatedLinkTypeEnum, feature_category: :portfolio_management do
  specify { expect(described_class.graphql_name).to eq('WorkItemRelatedLinkType') }

  it 'exposes all the existing access levels' do
    expected_fields = Gitlab.ee? ? %w[RELATED BLOCKS BLOCKED_BY] : %w[RELATED]

    expect(described_class.values.keys).to match_array(expected_fields)
  end
end
