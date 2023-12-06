# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_resource_sync_event, class: 'Ci::Catalog::Resources::SyncEvent' do
    catalog_resource factory: :ci_catalog_resource
    project { catalog_resource.project }
  end
end
