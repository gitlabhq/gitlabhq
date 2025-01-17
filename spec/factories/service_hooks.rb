# frozen_string_literal: true

FactoryBot.define do
  factory :service_hook do
    url { generate(:url) }
    integration

    trait :url_variables do
      url_variables { { 'abc' => 'supers3cret', 'def' => 'foobar' } }
    end

    trait :token do
      token { generate(:token) }
    end
  end
end
