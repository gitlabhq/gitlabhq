# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent, class: 'Clusters::Agent' do
    project
    association :created_by_user, factory: :user

    sequence(:name) { |n| "agent-#{n}" }

    trait :in_group do
      association :project, :in_group
    end
  end
end
