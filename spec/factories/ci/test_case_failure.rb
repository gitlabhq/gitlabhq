# frozen_string_literal: true

FactoryBot.define do
  factory :ci_test_case_failure, class: 'Ci::TestCaseFailure' do
    build factory: :ci_build
    test_case factory: :ci_test_case
    failed_at { Time.current }
  end
end
