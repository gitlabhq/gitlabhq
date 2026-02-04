# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItemWidgetType'] do
  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetType') }

  it 'exposes all the existing widget type values' do
    expect(described_class.values.transform_values { |v| v.value }).to include(
      'DESCRIPTION' => :description
    )
  end

  describe '#widget_definition_class' do
    it 'returns SystemDefined::WidgetDefinition' do
      expect(described_class.widget_definition_class)
        .to eq(::WorkItems::TypesFramework::SystemDefined::WidgetDefinition)
    end

    context 'when work_item_system_defined_type flag is disabled' do
      it 'returns WidgetDefinition' do
        stub_feature_flags(work_item_system_defined_type: false)

        expect(described_class.widget_definition_class).to eq(::WorkItems::WidgetDefinition)
      end
    end
  end
end
