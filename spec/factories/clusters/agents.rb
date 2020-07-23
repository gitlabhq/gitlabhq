# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent, class: 'Clusters::Agent' do
    project

    sequence(:name) { |n| "agent-#{n}" }
  end
end
