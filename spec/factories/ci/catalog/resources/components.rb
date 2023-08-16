# frozen_string_literal: true

FactoryBot.define do
  factory :catalog_resource_component, class: 'Ci::Catalog::Resources::Component' do
    version factory: :catalog_resource_version
    catalog_resource { version.catalog_resource }
    project { version.project }
    name { catalog_resource.name }
  end
end
