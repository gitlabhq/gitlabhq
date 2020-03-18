# frozen_string_literal: true

FactoryBot.define do
  factory :ci_daily_report_result, class: 'Ci::DailyReportResult' do
    ref_path { Gitlab::Git::BRANCH_REF_PREFIX + 'master' }
    date { Time.zone.now.to_date }
    project
    last_pipeline factory: :ci_pipeline
    param_type { Ci::DailyReportResult.param_types[:coverage] }
    title { 'rspec' }
    value { 77.0 }
  end
end
