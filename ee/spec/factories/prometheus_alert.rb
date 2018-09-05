FactoryBot.define do
  factory :prometheus_alert do
    project
    operator :gt
    threshold 1

    environment do |alert|
      build(:environment, project: alert.project)
    end

    prometheus_metric do |alert|
      build(:prometheus_metric, project: alert.project)
    end
  end
end
