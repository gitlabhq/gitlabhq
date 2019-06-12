# frozen_string_literal: true

FactoryBot.define do
  factory :pages_domain_acme_order do
    pages_domain
    url { 'https://example.com/' }
    expires_at { 1.day.from_now }
    challenge_token { 'challenge_token' }
    challenge_file_content { 'filecontent' }

    private_key { OpenSSL::PKey::RSA.new(4096).to_pem }

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
