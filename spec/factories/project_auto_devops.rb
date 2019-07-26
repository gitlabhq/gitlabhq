# frozen_string_literal: true

FactoryBot.define do
  factory :project_auto_devops do
    project
    enabled true
    deploy_strategy :continuous

    trait :continuous_deployment do
      deploy_strategy ProjectAutoDevops.deploy_strategies[:continuous] # rubocop:disable FactoryBot/DynamicAttributeDefinedStatically
    end

    trait :manual_deployment do
      deploy_strategy ProjectAutoDevops.deploy_strategies[:manual] # rubocop:disable FactoryBot/DynamicAttributeDefinedStatically
    end

    trait :timed_incremental_deployment do
      deploy_strategy ProjectAutoDevops.deploy_strategies[:timed_incremental] # rubocop:disable FactoryBot/DynamicAttributeDefinedStatically
    end

    trait :disabled do
      enabled false
    end
  end
end
