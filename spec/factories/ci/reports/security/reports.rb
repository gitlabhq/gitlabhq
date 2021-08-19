# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_report, class: '::Gitlab::Ci::Reports::Security::Report' do
    type { :sast }
    pipeline { association(:ci_pipeline) }
    created_at { 2.weeks.ago }
    scanned_resources { [] }

    transient do
      findings { [] }
      scanners { [] }
      identifiers { [] }
    end

    after :build do |report, evaluator|
      evaluator.scanners.each { |s| report.add_scanner(s) }
      evaluator.identifiers.each { |id| report.add_identifier(id) }
      evaluator.findings.each { |o| report.add_finding(o) }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Report.new(type, pipeline, created_at)
    end
  end
end
