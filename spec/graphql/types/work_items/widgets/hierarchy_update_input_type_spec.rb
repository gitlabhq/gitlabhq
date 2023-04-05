# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::HierarchyUpdateInputType do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetHierarchyUpdateInput') }

  it 'accepts documented arguments' do
    expect(described_class.arguments.keys).to match_array(%w[parentId childrenIds adjacentWorkItemId relativePosition])
  end

  it 'sets the type of relative_position argument to RelativePositionTypeEnum' do
    expect(described_class.arguments['relativePosition'].type).to eq(Types::RelativePositionTypeEnum)
  end
end
