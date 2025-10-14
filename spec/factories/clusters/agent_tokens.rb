# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_token, class: 'Clusters::AgentToken' do
    association :agent, factory: :cluster_agent
    association :created_by_user, factory: :user

    sequence(:name) { |n| "agent-token-#{n}" }

    trait :revoked do
      status { :revoked }
    end

    trait :with_plaintext_token do
      token_encrypted { nil } # Don't set the encrypted token

      after(:build) do |token|
        # Let the model generate the token naturally
        token.save! if token.persisted? == false
      end
    end
  end
end
