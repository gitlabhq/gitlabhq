# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::Widgetable, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:work_item_type) { create(:work_item_type) }

  # Create a dummy class to include the concern for testing
  let(:mutation_class) do
    Class.new do
      include Mutations::WorkItems::Widgetable

      # Make private methods accessible for testing
      public :widget_definition_class
    end
  end

  let(:mutation_instance) { mutation_class.new }

  describe '#widget_definition_class' do
    it 'returns SystemDefined::WidgetDefinition class' do
      expect(mutation_instance.widget_definition_class)
        .to eq(::WorkItems::TypesFramework::SystemDefined::WidgetDefinition)
    end

    context 'when work_item_system_defined_type feature flag is disabled' do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it 'returns WidgetDefinition class' do
        expect(mutation_instance.widget_definition_class)
          .to eq(::WorkItems::WidgetDefinition)
      end
    end
  end
end
