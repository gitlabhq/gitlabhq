# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_report, class: '::Gitlab::Ci::Reports::Sbom::Report' do
    transient do
      num_components { 5 }
      components { build_list :ci_reports_sbom_component, num_components }
      source { association :ci_reports_sbom_source }
    end

    trait :invalid do
      after(:build) do |report, options|
        report.add_error('This report is invalid because it contains errors.')
      end
    end

    after(:build) do |report, options|
      options.components.each { |component| report.add_component(component) }
      report.set_source(options.source)
    end

    skip_create
  end
end
