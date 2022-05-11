# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_token, class: 'Clusters::AgentToken' do
    association :agent, factory: :cluster_agent
    association :created_by_user, factory: :user

    token_encrypted { Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(50)) }

    sequence(:name) { |n| "agent-token-#{n}" }

    trait :revoked do
      status { :revoked }
    end
  end
end
