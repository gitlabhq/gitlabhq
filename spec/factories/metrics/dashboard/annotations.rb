# frozen_string_literal: true

FactoryBot.define do
  factory :metrics_dashboard_annotation, class: '::Metrics::Dashboard::Annotation' do
    description { "Dashbaord annoation description" }
    dashboard_path { "custom_dashbaord.yml" }
    starting_at { Time.current }
    environment

    trait :with_cluster do
      cluster
      environment { nil }
    end
  end
end
