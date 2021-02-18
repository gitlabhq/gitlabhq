# frozen_string_literal: true

FactoryBot.define do
  factory :ci_daily_build_group_report_result, class: 'Ci::DailyBuildGroupReportResult' do
    ref_path { Gitlab::Git::BRANCH_REF_PREFIX + 'master' }
    date { Date.current }
    project
    last_pipeline factory: :ci_pipeline
    group_name { 'rspec' }
    group
    data do
      { 'coverage' => 77.0 }
    end
    default_branch { true }

    trait :on_feature_branch do
      ref_path { Gitlab::Git::BRANCH_REF_PREFIX + 'feature' }
      default_branch { false }
    end
  end
end
