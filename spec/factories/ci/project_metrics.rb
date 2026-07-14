# frozen_string_literal: true

FactoryBot.define do
  factory :ci_project_metric, class: 'Ci::ProjectMetric' do
    project

    trait :with_first_pipeline_succeeded do
      first_pipeline_succeeded_at { Time.current }
    end

    trait :ai_generated do
      ci_config_generated_by { 'ci_expert_agent/v1' }
    end

    trait :with_ai_pipeline_results_viewed do
      first_ai_pipeline_results_viewed_at { Time.current }
    end
  end
end
