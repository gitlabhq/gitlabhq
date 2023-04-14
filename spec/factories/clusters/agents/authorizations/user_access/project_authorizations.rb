# frozen_string_literal: true

FactoryBot.define do
  factory :agent_user_access_project_authorization,
    class: 'Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization' do
    association :agent, factory: :cluster_agent
    config { {} }
    project
  end
end
