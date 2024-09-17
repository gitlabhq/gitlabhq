# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WorkItemTypeDepthLimitReachedByType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[work_item_type depth_limit_reached]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
