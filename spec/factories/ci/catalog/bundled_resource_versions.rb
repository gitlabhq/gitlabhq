# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_bundled_resource_version, class: 'Ci::Catalog::BundledResources::Version' do
    bundled_resource factory: :ci_catalog_bundled_resource
    semver { '1.0.0' }
  end
end
