# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_component, class: '::Gitlab::Ci::Reports::Sbom::Component' do
    type { "library" }

    sequence(:name) { |n| "component-#{n}" }
    sequence(:version) { |n| "v0.0.#{n}" }

    transient do
      purl_type { 'npm' }
    end

    purl do
      ::Sbom::PackageUrl.new(
        type: purl_type,
        name: name,
        version: version
      ).to_s
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Sbom::Component.new(
        type: type,
        name: name,
        purl: purl,
        version: version
      )
    end
  end
end
