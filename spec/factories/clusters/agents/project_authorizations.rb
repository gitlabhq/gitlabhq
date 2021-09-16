# frozen_string_literal: true

FactoryBot.define do
  factory :agent_project_authorization, class: 'Clusters::Agents::ProjectAuthorization' do
    association :agent, factory: :cluster_agent
    project

    config { { default_namespace: 'production' } }
  end
end
