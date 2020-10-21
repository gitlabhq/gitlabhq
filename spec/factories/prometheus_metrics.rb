# frozen_string_literal: true

FactoryBot.define do
  factory :prometheus_metric, class: 'PrometheusMetric' do
    title { 'title' }
    query { 'avg(metric)' }
    y_label { 'y_label' }
    unit { 'm/s' }
    group { :business }
    project
    legend { 'legend' }
    dashboard_path { '.gitlab/dashboards/dashboard_path.yml'}

    trait :common do
      common { true }
      project { nil }
    end
  end
end
