# frozen_string_literal: true

FactoryBot.define do
  factory :prometheus_alert do
    project
    operator { :gt }
    threshold { 1 }

    environment do |alert|
      build(:environment, project: alert.project)
    end

    prometheus_metric do |alert|
      build(:prometheus_metric, project: alert.project)
    end

    trait :with_runbook_url do
      runbook_url { 'https://runbooks.gitlab.com/metric_gt_1'}
    end
  end
end
