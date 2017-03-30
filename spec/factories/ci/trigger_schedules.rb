FactoryGirl.define do
  factory :ci_trigger_schedule, class: Ci::TriggerSchedule do
    project factory: :project
    trigger factory: :ci_trigger_with_ref

    trait :force_triggable do
      after(:create) do |trigger_schedule, evaluator|
        trigger_schedule.next_run_at -= 1.month
      end
    end

    trait :cron_nightly_build do
      cron '0 1 * * *'
      cron_time_zone Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end

    trait :cron_weekly_build do
      cron '0 1 * * 6'
      cron_time_zone Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end

    trait :cron_monthly_build do
      cron '0 1 22 * *'
      cron_time_zone Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    end
  end
end
