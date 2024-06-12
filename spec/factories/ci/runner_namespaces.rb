# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_namespace, class: 'Ci::RunnerNamespace' do
    group

    after(:build) do |runner_namespace, evaluator|
      if runner_namespace.runner.nil?
        runner_namespace.runner = build(:ci_runner, :group, runner_namespaces: [runner_namespace])
        runner_namespace.namespace = evaluator.group
      end
    end
  end
end
