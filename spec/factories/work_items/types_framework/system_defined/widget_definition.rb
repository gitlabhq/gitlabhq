# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_system_defined_widget_definition,
    class: 'WorkItems::TypesFramework::SystemDefined::WidgetDefinition' do
    skip_create

    transient do
      widget_type { 'description' }
      work_item_type_id { build(:work_item_system_defined_type).id }
    end

    initialize_with do
      # There were some issues in the spec where the widget definitions were not created correcty.
      # To ensure that the widget definitions are correctly loaded, we reset the storage and reload them.
      klass = WorkItems::TypesFramework::SystemDefined::WidgetDefinition
      klass.instance_variable_set(:@storage, nil)
      klass.all

      klass.find_by(widget_type: widget_type, work_item_type_id: work_item_type_id)
    end

    trait :description do
      widget_type { 'description' }
    end
  end
end
