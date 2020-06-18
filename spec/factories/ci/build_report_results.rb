# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_report_result, class: 'Ci::BuildReportResult' do
    build factory: :ci_build
    project factory: :project
    data do
      {
        tests: {
          name: "rspec",
          duration: 0.42,
          failed: 0,
          errored: 2,
          skipped: 0,
          success: 0
        }
      }
    end

    trait :with_junit_success do
      data do
        {
          tests: {
            name: "rspec",
            duration: 0.42,
            failed: 0,
            errored: 0,
            skipped: 0,
            success: 2
          }
        }
      end
    end
  end
end
