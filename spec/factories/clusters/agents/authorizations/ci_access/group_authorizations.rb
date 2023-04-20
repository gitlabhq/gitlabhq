# frozen_string_literal: true

FactoryBot.define do
  factory :agent_ci_access_group_authorization, class: 'Clusters::Agents::Authorizations::CiAccess::GroupAuthorization' do
    association :agent, factory: :cluster_agent
    group

    transient do
      environments { nil }
    end

    config do
      { default_namespace: 'production' }.tap do |c|
        c[:environments] = environments if environments
      end
    end
  end
end
