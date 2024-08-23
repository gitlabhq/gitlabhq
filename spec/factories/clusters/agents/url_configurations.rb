# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_agent_url_configuration, class: 'Clusters::Agents::UrlConfiguration' do
    association :agent, factory: :cluster_agent
    association :created_by_user, factory: :user
    url { 'grpc://agent.example.com' }
    certificate_auth

    before(:create) do |url_config|
      url_config.project = url_config.agent.project
    end

    trait :certificate_auth do
      client_cert { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
      client_key { File.read(Rails.root.join('spec/fixtures/clusters/sample_key.key')) }
    end

    trait :public_key_auth do
      client_cert { nil }
      client_key { nil }

      before(:create) do |url_config|
        private_key = Ed25519::SigningKey.generate
        public_key = private_key.verify_key

        url_config.private_key = private_key.to_bytes
        url_config.public_key = public_key.to_bytes
      end
    end

    trait :revoked do
      status { :revoked }
    end
  end
end
