# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetDefinitions::HierarchyType, feature_category: :team_planning do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('WorkItemWidgetDefinitionHierarchy') }

  it 'exposes the expected fields' do
    expected_fields = %w[allowedChildTypes allowedParentTypes propagates_milestone auto_expand_tree_on_move]

    expected_fields.each do |field|
      expect(described_class).to have_graphql_field(field)
    end
  end

  it 'allowedChildTypes and allowedParentTypes are a connection type of Types::WorkItems::TypeType' do
    expected_fields = %w[allowedChildTypes allowedParentTypes]

    expected_fields.each do |field|
      expect(described_class.fields[field]).to have_graphql_type(Types::WorkItems::TypeType.connection_type)
    end
  end

  describe '#propagates_milestone' do
    let(:work_item_type) { build(:work_item_system_defined_type, :issue) }
    let(:widget_definition) do
      build(:work_item_system_defined_widget_definition, widget_type: 'hierarchy',
        work_item_type_id: work_item_type.id)
    end

    let(:user) { create(:user) }

    subject(:result) { resolve_field(:propagates_milestone, widget_definition, current_user: user) }

    context 'when widget_options is nil' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(nil)
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when widget_options exists but progress options are not set' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return({})
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when show_popover is set to true' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(
          { hierarchy: { propagates_milestone: true } }
        )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when show_popover is set to false' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(
          { hierarchy: { propagates_milestone: false } }
        )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end
  end

  describe '#auto_expand_tree_on_move' do
    let(:work_item_type) { build(:work_item_system_defined_type, :issue) }
    let(:widget_definition) do
      build(:work_item_system_defined_widget_definition, widget_type: 'hierarchy',
        work_item_type_id: work_item_type.id)
    end

    let(:user) { create(:user) }

    subject(:result) { resolve_field(:auto_expand_tree_on_move, widget_definition, current_user: user) }

    context 'when widget_options is nil' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(nil)
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when widget_options exists but progress options are not set' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return({})
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when show_popover is set to true' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(
          { hierarchy: { auto_expand_tree_on_move: true } }
        )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when show_popover is set to false' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(
          { hierarchy: { auto_expand_tree_on_move: false } }
        )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end
  end
end
