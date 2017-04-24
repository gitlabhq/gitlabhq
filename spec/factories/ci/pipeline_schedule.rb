FactoryGirl.define do
  factory :ci_pipeline_schedule, class: Ci::PipelineSchedule do
    trigger factory: :ci_trigger
    cron '0 1 * * *'
    cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    ref 'master'
    active true
    description "trigger schedule"

    after(:build) do |trigger_schedule, evaluator|
      trigger_schedule.project ||= trigger_schedule.trigger.project
    end

    trait :nightly do
      cron '0 1 * * *'
      cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end

    trait :weekly do
      cron '0 1 * * 6'
      cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end

    trait :monthly do
      cron '0 1 22 * *'
      cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end

    trait :inactive do
      active false
    end
  end
end
