# frozen_string_literal: true

FactoryBot.define do
  factory :agent_ci_access_organization_authorization,
    class: 'Clusters::Agents::Authorizations::CiAccess::OrganizationAuthorization' do
    association :agent, factory: :cluster_agent
    organization { agent.project.organization }

    transient do
      environments { nil }
      protected_branches_only { false }
      resource_management_enabled { false }
    end

    config do
      { default_namespace: 'production' }.tap do |c|
        c[:environments] = environments if environments
        c[:protected_branches_only] = protected_branches_only
        c[:resource_management] = { enabled: true } if resource_management_enabled
      end
    end
  end
end
