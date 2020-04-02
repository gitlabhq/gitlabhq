# frozen_string_literal: true

FactoryBot.define do
  factory :test_case, class: 'Gitlab::Ci::Reports::TestCase' do
    name { "test-1" }
    classname { "trace" }
    file { "spec/trace_spec.rb" }
    execution_time { 1.23 }
    status { "success" }
    system_output { nil }
    attachment { nil }
    association :job, factory: :ci_build

    trait :failed do
      status { "failed" }
    end

    trait :with_attachment do
      status { "failed" }
      attachment { "some/path.png" }
    end

    skip_create

    initialize_with do
      new(
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
