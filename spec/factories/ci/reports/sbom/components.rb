# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_component, class: '::Gitlab::Ci::Reports::Sbom::Component' do
    type { "library" }

    sequence(:name) { |n| "component-#{n}" }
    sequence(:version) { |n| "v0.0.#{n}" }

    transient do
      purl_type { 'npm' }
      namespace { nil }
      source_package_name { nil }
    end

    purl do
      ::Sbom::PackageUrl.new(
        type: purl_type,
        name: name,
        namespace: namespace,
        version: version
      )
    end

    trait :with_source_package_name do
      sequence(:source_package_name) { |n| "source-package-name-#{n}" }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Sbom::Component.new(
        type: type,
        name: name,
        purl: purl,
        version: version,
        source_package_name: source_package_name
      )
    end
  end
end
