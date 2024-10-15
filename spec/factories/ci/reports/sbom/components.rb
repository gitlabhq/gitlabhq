# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_component, class: '::Gitlab::Ci::Reports::Sbom::Component' do
    type { "library" }

    sequence(:ref) { |n| "ref-#{n}" }
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

    properties { nil }

    trait :with_trivy_properties do
      properties do
        Gitlab::Ci::Parsers::Sbom::CyclonedxProperties.parse_component_source([
          { 'name' => 'aquasecurity:trivy:PkgType', 'value' => 'node-pkg' },
          { 'name' => 'aquasecurity:trivy:FilePath',
            'value' => 'usr/local/lib/node_modules/npm/node_modules/@colors/colors/package.json' }
        ])
      end
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Sbom::Component.new(
        ref: ref,
        type: type,
        name: name,
        purl: purl,
        version: version,
        source_package_name: source_package_name
      )
    end
  end
end
