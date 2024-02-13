# frozen_string_literal: true

FactoryBot.define do
  factory :service_access_token, class: 'CloudConnector::ServiceAccessToken' do
    token { SecureRandom.alphanumeric(10) }
    expires_at { Time.current + 1.day }

    trait :active do
      expires_at { Time.current + 1.day }
    end

    trait :expired do
      expires_at { Time.current - 1.day }
    end
  end
end
