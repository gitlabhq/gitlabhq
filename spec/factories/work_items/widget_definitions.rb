# frozen_string_literal: true

FactoryBot.define do
  factory :widget_definition, class: 'WorkItems::WidgetDefinition' do
    association :work_item_type, :non_default

    name { 'Description' }
    widget_type { 'description' }
    widget_options { { editable: true, rollup: false } if widget_type == 'weight' }
  end
end
