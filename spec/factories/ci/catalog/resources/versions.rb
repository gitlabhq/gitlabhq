# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_resource_version, class: 'Ci::Catalog::Resources::Version' do
    semver { '1.0.0' }

    catalog_resource factory: :ci_catalog_resource
    project { catalog_resource.project }
    release { association :release, project: project }
    published_by { release.author }
  end
end
