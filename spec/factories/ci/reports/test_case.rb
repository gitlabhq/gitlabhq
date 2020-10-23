# frozen_string_literal: true

FactoryBot.define do
  factory :report_test_case, class: 'Gitlab::Ci::Reports::TestCase' do
    suite_name { "rspec" }
    name { "test-1" }
    classname { "trace" }
    file { "spec/trace_spec.rb" }
    execution_time { 1.23 }
    status { Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS }
    system_output { nil }
    attachment { nil }
    association :job, factory: :ci_build

    trait :failed do
      status { Gitlab::Ci::Reports::TestCase::STATUS_FAILED }
      system_output { "Failure/Error: is_expected.to eq(300) expected: 300 got: -100" }
    end

    trait :failed_with_attachment do
      status { Gitlab::Ci::Reports::TestCase::STATUS_FAILED }
      attachment { "some/path.png" }
    end

    skip_create

    initialize_with do
      new(
        suite_name: suite_name,
        name: name,
        classname: classname,
        file: file,
        execution_time: execution_time,
        status: status,
        system_output: system_output,
        attachment: attachment,
        job: job
      )
    end
  end
end
