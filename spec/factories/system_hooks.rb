# frozen_string_literal: true

FactoryBot.define do
  factory :system_hook do
    url { generate(:url) }
    name { generate(:name) }
    description { "Description of #{name}" }

    trait :url_variables do
      url_variables { { 'abc' => 'supers3cret', 'def' => 'foobar' } }
    end

    trait :token do
      token { generate(:token) }
    end
  end
end
