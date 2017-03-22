FactoryGirl.define do
  factory :ci_scheduled_trigger, class: Ci::ScheduledTrigger do
    project factory: :empty_project
    owner factory: :user
    ref 'master'

    trait :cron_nightly_build do
      cron '0 1 * * *'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_weekly_build do
      cron '0 1 * * 5'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_monthly_build do
      cron '0 1 22 * *'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_every_5_minutes do
      cron '*/5 * * * *'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_every_5_hours do
      cron '* */5 * * *'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_every_5_days do
      cron '* * */5 * *'
      cron_time_zone 'Europe/Istanbul'
    end

    trait :cron_every_5_months do
      cron '* * * */5 *'
      cron_time_zone 'Europe/Istanbul'
    end
  end
end
