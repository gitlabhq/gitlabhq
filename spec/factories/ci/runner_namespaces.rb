# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_namespace, class: 'Ci::RunnerNamespace' do
    runner factory: [:ci_runner, :group]
    group
  end
end
