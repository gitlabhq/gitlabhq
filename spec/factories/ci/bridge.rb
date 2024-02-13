# frozen_string_literal: true

require_relative 'deployable'

FactoryBot.define do
  factory :ci_bridge, class: 'Ci::Bridge', parent: :ci_processable do
    instance_eval ::Factories::Ci::Deployable.traits

    name { 'bridge' }
    created_at { '2013-10-29 09:50:00 CET' }
    status { :created }

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

    trait :retried do
      retried { true }
    end

    trait :retryable do
      success
    end

    trait :created do
      status { 'created' }
    end

    trait :running do
      status { 'running' }
    end

    trait :started do
      started_at { '2013-10-29 09:51:28 CET' }
    end

    trait :finished do
      started
      finished_at { '2013-10-29 09:53:28 CET' }
    end

    trait :success do
      finished
      status { 'success' }
    end

    trait :failed do
      finished
      status { 'failed' }
    end

    trait :canceled do
      finished
      status { 'canceled' }
    end

    trait :skipped do
      started
      status { 'skipped' }
    end

    trait :strategy_depend do
      options { { trigger: { strategy: 'depend' } } }
    end

    trait :manual do
      status { 'manual' }
      self.when { 'manual' }
    end

    trait :playable do
      manual
    end

    trait :allowed_to_fail do
      allow_failure { true }
    end
  end
end
