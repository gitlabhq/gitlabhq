FactoryBot.define do
  factory :ci_bridge, class: Ci::Bridge do
    name ' bridge'
    stage 'test'
    stage_idx 0
    ref 'master'
    tag false
    created_at 'Di 29. Okt 09:50:00 CET 2013'
    status :success

    pipeline factory: :ci_pipeline

    after(:build) do |bridge, evaluator|
      bridge.project ||= bridge.pipeline.project
    end
  end
end
