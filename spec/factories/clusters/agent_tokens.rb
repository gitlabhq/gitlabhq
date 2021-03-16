# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_token, class: 'Clusters::AgentToken' do
    association :agent, factory: :cluster_agent

    token_encrypted { Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(50)) }

    sequence(:name) { |n| "agent-token-#{n}" }
  end
end
