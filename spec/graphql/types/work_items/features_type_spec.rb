# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::FeaturesType, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItemFeatures') }

  it 'exposes widget fields' do
    fields = WorkItems::WidgetDefinition.widget_classes.map(&:type)

    expect(described_class).to have_graphql_fields(*fields).at_least
  end

  describe '#widget_definition_class' do
    it 'returns SystemDefined::WidgetDefinition' do
      expect(described_class.widget_definition_class)
        .to eq(::WorkItems::TypesFramework::SystemDefined::WidgetDefinition)
    end
  end

  context 'when work_item_system_defined_type flag is disabled' do
    it 'returns WidgetDefinition' do
      stub_feature_flags(work_item_system_defined_type: false)

      expect(described_class.widget_definition_class).to eq(::WorkItems::WidgetDefinition)
    end
  end
end
