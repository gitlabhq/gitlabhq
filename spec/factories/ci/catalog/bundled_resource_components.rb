# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_bundled_resource_component, class: 'Ci::Catalog::BundledResources::Component' do
    version factory: :ci_catalog_bundled_resource_version
    bundled_resource { version.bundled_resource }
    sequence(:name) { |n| "component-#{n}" }
  end
end
