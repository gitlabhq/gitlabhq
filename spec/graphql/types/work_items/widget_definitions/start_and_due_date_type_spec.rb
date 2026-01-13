# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetDefinitions::StartAndDueDateType, feature_category: :team_planning do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('WorkItemWidgetDefinitionStartAndDueDate') }

  it 'exposes the expected fields' do
    expected_fields = %w[type can_roll_up]

    expected_fields.each do |field|
      expect(described_class).to have_graphql_field(field)
    end
  end

  describe '#can_roll_up' do
    let(:work_item_type) { build(:work_item_system_defined_type, :issue) }
    let(:widget_definition) do
      build(:work_item_system_defined_widget_definition, widget_type: 'start_and_due_date',
        work_item_type_id: work_item_type.id)
    end

    let(:user) { create(:user) }

    subject(:result) { resolve_field(:can_roll_up, widget_definition, current_user: user) }

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
          { start_and_due_date: { can_roll_up: true } }
        )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when show_popover is set to false' do
      before do
        allow(widget_definition).to receive(:widget_options).and_return(
          { start_and_due_date: { can_roll_up: false } }
        )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end
  end
end
