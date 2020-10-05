# frozen_string_literal: true

FactoryBot.define do
  factory :instance_statistics_measurement, class: 'Analytics::InstanceStatistics::Measurement' do
    recorded_at { Time.now }
    identifier { :projects }
    count { 1_000 }

    trait :project_count do
      identifier { :projects }
    end

    trait :group_count do
      identifier { :groups }
    end

    trait :pipelines_succeeded_count do
      identifier { :pipelines_succeeded }
    end

    trait :pipelines_skipped_count do
      identifier { :pipelines_skipped }
    end
  end
end
