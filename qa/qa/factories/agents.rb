# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/cluster_agents.html
    factory :cluster_agent, class: 'QA::Resource::Clusters::Agent'

    # https://docs.gitlab.com/ee/api/cluster_agents.html#create-an-agent-token
    factory :cluster_agent_token, class: 'QA::Resource::Clusters::AgentToken'
  end
end
