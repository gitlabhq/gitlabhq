# frozen_string_literal: true

FactoryBot.define do
  factory :widget_definition, class: 'WorkItems::WidgetDefinition' do
    work_item_type
    namespace

    name { 'Description' }
    widget_type { 'description' }

    trait :default do
      namespace { nil }
    end
  end
end
