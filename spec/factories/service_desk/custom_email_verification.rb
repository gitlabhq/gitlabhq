# frozen_string_literal: true

FactoryBot.define do
  factory :service_desk_custom_email_verification, class: '::ServiceDesk::CustomEmailVerification' do
    state { 'started' }
    token { 'XXXXXXXXXXXX' }
    project
    triggerer factory: :user
    triggered_at { Time.current }

    trait :overdue do
      triggered_at { (ServiceDesk::CustomEmailVerification::TIMEFRAME + 1).minutes.ago }
    end

    trait :finished do
      state { 'finished' }
      token { nil }
    end
  end
end
