FactoryBot.define do
  factory :prometheus_alert do
    project
    environment
    prometheus_metric
    operator :gt
    threshold 1
  end
end
