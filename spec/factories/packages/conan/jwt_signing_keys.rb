# frozen_string_literal: true

FactoryBot.define do
  factory :conan_jwt_signing_key, class: 'Packages::Conan::JwtSigningKey' do
    secret_key { SecureRandom.hex(64) }
  end
end
