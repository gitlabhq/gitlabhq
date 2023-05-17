# frozen_string_literal: true

FactoryBot.define do
  factory :agent_user_access_group_authorization,
    class: 'Clusters::Agents::Authorizations::UserAccess::GroupAuthorization' do
    association :agent, factory: :cluster_agent
    config { {} }
    group
  end
end
