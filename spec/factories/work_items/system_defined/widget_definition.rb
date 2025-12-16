# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_system_defined_widget_definition, class: 'WorkItems::SystemDefined::WidgetDefinition' do
    skip_create
    description
    association :work_item_type, factory: :work_item_system_defined_type, strategy: :build

    initialize_with do
      WorkItems::SystemDefined::WidgetDefinition.find_by(
        widget_type: attributes[:widget_type] || 'description',
        work_item_type_id: attributes[:work_item_type_id] || build(:work_item_system_defined_type, :issue).id
      )
    end

    widget_options { { editable: true, rollup: false } if widget_type == 'weight' }

    trait :description do
      name { 'Description' }
      widget_type { 'description' }
    end
  end
end
