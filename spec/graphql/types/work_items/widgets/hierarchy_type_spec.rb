# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::HierarchyType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[parent children has_children has_parent ancestors type rolled_up_counts_by_type
      depthLimitReachedByType]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
