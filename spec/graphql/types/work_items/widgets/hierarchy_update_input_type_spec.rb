# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::HierarchyUpdateInputType do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetHierarchyUpdateInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[parentId childrenIds]) }
end
