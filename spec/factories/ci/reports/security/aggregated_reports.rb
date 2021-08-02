# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_aggregated_reports, class: '::Gitlab::Ci::Reports::Security::AggregatedReport' do
    reports { FactoryBot.build_list(:ci_reports_security_report, 1) }
    findings { FactoryBot.build_list(:ci_reports_security_finding, 1) }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::AggregatedReport.new(reports, findings)
    end
  end
end
