# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_namespace, class: 'Ci::RunnerNamespace' do
    group

    after(:build) do |runner_namespace, evaluator|
      unless runner_namespace.runner.present?
        runner_namespace.runner = build(
          :ci_runner, :group, runner_namespaces: [runner_namespace]
        )
      end
    end
  end
end
