# frozen_string_literal: true

FactoryBot.define do
  factory :system_hook do
    url { generate(:url) }
    name { generate(:name) }
    description { "Description of #{name}" }
    organization { association(:organization) }
    filter { {} }

    trait :url_variables do
      url_variables { { 'abc' => 'supers3cret', 'def' => 'foobar' } }
    end

    trait :token do
      token { generate(:token) }
    end

    trait :signing_token do
      signing_token { "whsec_#{Base64.strict_encode64(SecureRandom.bytes(32))}" }
    end
  end
end
