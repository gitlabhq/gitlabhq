# frozen_string_literal: true

FactoryBot.define do
  factory :metrics_dashboard_annotation, class: '::Metrics::Dashboard::Annotation' do
    description { "Dashbaord annoation description" }
    dashboard_path { "custom_dashbaord.yml" }
    starting_at { Time.current }
  end
end
