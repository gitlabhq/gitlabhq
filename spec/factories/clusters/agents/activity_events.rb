# frozen_string_literal: true

FactoryBot.define do
  factory :agent_activity_event, class: 'Clusters::Agents::ActivityEvent' do
    association :agent, factory: :cluster_agent
    association :agent_token, factory: :cluster_agent_token
    user

    kind { :token_created }
    level { :info }
    recorded_at { Time.current }
  end
end
