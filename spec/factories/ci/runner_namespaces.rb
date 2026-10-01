# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_namespace, class: 'Ci::RunnerNamespace' do
    group
    namespace { group }
    runner { association(:ci_runner, :group, groups: [namespace], runner_namespaces: [instance]) }
  end
end
