# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_report, class: '::Gitlab::Ci::Reports::Sbom::Report' do
    transient do
      sbom_attributes do
        {
          bom_format: 'CycloneDX',
          spec_version: '1.4',
          serial_number: "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
          version: 1
        }
      end
      num_components { 5 }
      components { build_list :ci_reports_sbom_component, num_components }
      source { association :ci_reports_sbom_source }
    end

    trait :invalid do
      transient do
        error { 'This report is invalid because it contains errors.' }
      end
      after(:build) do |report, options|
        report.add_error(options.error)
      end
    end

    trait(:with_metadata) do
      transient do
        metadata { association(:ci_reports_sbom_metadata) }
      end

      after(:build) do |report, options|
        report.metadata = options.metadata
      end
    end

    after(:build) do |report, options|
      options.components.each { |component| report.add_component(component) } if options.components
      report.set_source(options.source)
    end

    skip_create
  end
end
