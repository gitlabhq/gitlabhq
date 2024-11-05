# frozen_string_literal: true

FactoryBot.define do
  factory :catalog_resource_component_last_usage, class: 'Ci::Catalog::Resources::Components::LastUsage' do
    component factory: :ci_catalog_resource_component
    catalog_resource { component.catalog_resource }
    component_project { component.project }
    sequence(:used_by_project_id)
    last_used_date { Date.current }
  end
end
