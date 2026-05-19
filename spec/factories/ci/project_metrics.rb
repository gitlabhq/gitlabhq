# frozen_string_literal: true

FactoryBot.define do
  factory :ci_project_metric, class: 'Ci::ProjectMetric' do
    project

    trait :with_first_pipeline_succeeded do
      first_pipeline_succeeded_at { Time.current }
    end
  end
end
