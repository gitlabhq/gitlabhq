# frozen_string_literal: true

FactoryBot.define do
  factory :agent_group_authorization, class: 'Clusters::Agents::GroupAuthorization' do
    association :agent, factory: :cluster_agent
    group

    config { { default_namespace: 'production' } }
  end
end
