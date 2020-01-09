# frozen_string_literal: true

FactoryBot.define do
  factory :ci_bridge, class: 'Ci::Bridge' do
    name { 'bridge' }
    stage { 'test' }
    stage_idx { 0 }
    ref { 'master' }
    tag { false }
    created_at { 'Di 29. Okt 09:50:00 CET 2013' }
    status { :created }

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
  end
end
