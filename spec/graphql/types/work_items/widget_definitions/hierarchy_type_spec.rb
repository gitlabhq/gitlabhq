# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetDefinitions::HierarchyType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetDefinitionHierarchy') }

  it 'exposes the expected fields' do
    expected_fields = %w[allowedChildTypes allowedParentTypes]

    expected_fields.each do |field|
      expect(described_class).to have_graphql_field(field)
      expect(described_class.fields[field]).to have_graphql_type(Types::WorkItems::TypeType.connection_type)
    end
  end
end
