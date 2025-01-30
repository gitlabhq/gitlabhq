# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_migration, class: 'Clusters::AgentMigration' do
    association :cluster, :group
    association :agent, factory: :cluster_agent
    project

    before(:create) do |migration|
      migration.project = migration.agent.project
    end

    agent_install_status { :pending }
  end
end
