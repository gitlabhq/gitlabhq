# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetDefinitionInterface, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[
      type
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '.resolve_type' do
    subject { described_class.resolve_type(object, {}) }

    context 'for assignees widget' do
      let(:object) do
        build(:work_item_system_defined_widget_definition, widget_type: 'assignees')
      end

      it { is_expected.to eq(Types::WorkItems::WidgetDefinitions::AssigneesType) }
    end

    context 'for hierarchy widget' do
      let(:object) do
        build(:work_item_system_defined_widget_definition, widget_type: 'hierarchy')
      end

      it { is_expected.to eq(Types::WorkItems::WidgetDefinitions::HierarchyType) }
    end

    context 'for other widgets' do
      let(:object) do
        build(:work_item_system_defined_widget_definition, widget_type: 'description')
      end

      it { is_expected.to eq(Types::WorkItems::WidgetDefinitions::GenericType) }
    end
  end
end
