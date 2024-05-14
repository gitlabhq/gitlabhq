# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_resource_component_usage, class: 'Ci::Catalog::Resources::Components::Usage' do
    component factory: :ci_catalog_resource_component
    catalog_resource { component.catalog_resource }
    project { component.project }
    used_by_project_id { 1 }
  end
end
