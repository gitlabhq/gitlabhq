# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_migration, class: 'Clusters::AgentMigration' do
    association :cluster, :instance
    association :agent, factory: :cluster_agent
    project

    before(:create) do |migration|
      migration.project = migration.agent.project
      migration.agent_name = migration.agent.name
    end

    agent_install_status { :pending }
  end
end
