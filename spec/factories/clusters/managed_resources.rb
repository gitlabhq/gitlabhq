# frozen_string_literal: true

FactoryBot.define do
  factory :managed_resource, class: 'Clusters::Agents::ManagedResource' do
    project
    environment
    association :cluster_agent
    association :build
  end
end
