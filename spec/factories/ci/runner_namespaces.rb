# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_namespace, class: 'Ci::RunnerNamespace' do
    # FactoryBot sets attributes in this order. A nil `group` clears `namespace_id`,
    # so `namespace` must come after it.
    group { namespace if namespace.group_namespace? }
    namespace { @overrides[:group] || association(:group) }
    runner { association(:ci_runner, :group, groups: [namespace], runner_namespaces: [instance]) }
  end
end
