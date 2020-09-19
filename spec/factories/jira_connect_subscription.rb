# frozen_string_literal: true

FactoryBot.define do
  factory :jira_connect_subscription do
    association :installation, factory: :jira_connect_installation
    association :namespace, factory: :group
  end
end
