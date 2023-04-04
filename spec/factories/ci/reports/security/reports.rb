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

    factory :dependency_scanning_security_report do
      type { :dependency_scanning }

      after :create do |report|
        artifact = report.pipeline.job_artifacts.dependency_scanning.last
        if artifact.present?
          content = File.read(artifact.file.path)

          Gitlab::Ci::Parsers::Security::DependencyScanning.parse!(content, report)
        end
      end
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Report.new(type, pipeline, created_at)
    end
  end
end
