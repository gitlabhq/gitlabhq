# frozen_string_literal: true

FactoryBot.define do
  factory :ci_bridge, class: 'Ci::Bridge' do
    name { 'bridge' }
    stage { 'test' }
    stage_idx { 0 }
    ref { 'master' }
    tag { false }
    created_at { '2013-10-29 09:50:00 CET' }
    status { :created }
    scheduling_type { 'stage' }

    pipeline factory: :ci_pipeline

    trait :variables do
      yaml_variables do
        [{ key: 'BRIDGE', value: 'cross', public: true }]
      end
    end

    transient do
      downstream { nil }
      upstream { nil }
    end

    after(:build) do |bridge, evaluator|
      bridge.project ||= bridge.pipeline.project

      if evaluator.downstream.present?
        bridge.options = bridge.options.to_h.merge(
          trigger: { project: evaluator.downstream.full_path }
        )
      end

      if evaluator.upstream.present?
        bridge.options = bridge.options.to_h.merge(
          bridge_needs: { pipeline: evaluator.upstream.full_path }
        )
      end
    end

    trait :started do
      started_at { '2013-10-29 09:51:28 CET' }
    end

    trait :finished do
      started
      finished_at { '2013-10-29 09:53:28 CET' }
    end

    trait :failed do
      finished
      status { 'failed' }
    end
  end
end
