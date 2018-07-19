FactoryBot.define do
  factory :prometheus_alert do
    project
    environment
    prometheus_metric
    name { generate(:title) }
    query "foo"
    operator :gt
    threshold 1
  end
end
