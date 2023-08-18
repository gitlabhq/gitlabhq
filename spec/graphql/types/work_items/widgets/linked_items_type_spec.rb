# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::LinkedItemsType, feature_category: :portfolio_management do
  it 'exposes the expected fields' do
    expected_fields = %i[type linkedItems]

    expect(described_class.graphql_name).to eq('WorkItemWidgetLinkedItems')
    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
