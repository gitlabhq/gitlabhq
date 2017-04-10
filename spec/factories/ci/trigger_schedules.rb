FactoryGirl.define do
  factory :ci_trigger_schedule, class: Ci::TriggerSchedule do
    trigger factory: :ci_trigger_for_trigger_schedule
    cron '0 1 * * *'
    cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    ref 'master'
    active true

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
  end
end
