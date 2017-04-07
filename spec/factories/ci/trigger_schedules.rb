FactoryGirl.define do
  factory :ci_trigger_schedule, class: Ci::TriggerSchedule do
    trigger factory: :ci_trigger_for_trigger_schedule
    cron '0 1 * * *'
    cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE

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
