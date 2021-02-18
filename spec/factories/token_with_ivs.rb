# frozen_string_literal: true

FactoryBot.define do
  factory :token_with_iv do
    hashed_token { ::Digest::SHA256.digest(SecureRandom.hex(50)) }
    iv { ::Digest::SHA256.digest(SecureRandom.hex(50)) }
    hashed_plaintext_token { ::Digest::SHA256.digest(SecureRandom.hex(50)) }
  end
end
