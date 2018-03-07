FactoryBot.define do
  factory :ci_pipeline_schedule, class: Ci::PipelineSchedule do
    cron '0 1 * * *'
    cron_timezone Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE
    ref 'master'
    active true
    description "pipeline schedule"
    project

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
