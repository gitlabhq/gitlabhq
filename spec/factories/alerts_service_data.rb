# frozen_string_literal: true

FactoryBot.define do
  factory :alerts_service_data do
    service { association(:alerts_service) }
    token { SecureRandom.hex }
  end
end
