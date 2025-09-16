# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::DiscussionsSortEnum, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItemDiscussionsSort') }

  it 'exposes all the work item discussion sort values' do
    expect(described_class.values.keys).to match_array(
      %w[CREATED_ASC CREATED_DESC]
    )
  end

  it 'returns CREATED_ASC as the default value' do
    expect(described_class.default_value).to eq(:created_asc)
  end
end
