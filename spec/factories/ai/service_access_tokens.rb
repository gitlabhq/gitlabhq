# frozen_string_literal: true

FactoryBot.define do
  factory :service_access_token, class: 'Ai::ServiceAccessToken' do
    token { SecureRandom.alphanumeric(10) }
    expires_at { Time.current + 1.day }
    category { :code_suggestions }

    trait :active do
      expires_at { Time.current + 1.day }
    end

    trait :expired do
      expires_at { Time.current - 1.day }
    end

    trait :code_suggestions do
      category { :code_suggestions }
    end
  end
end
