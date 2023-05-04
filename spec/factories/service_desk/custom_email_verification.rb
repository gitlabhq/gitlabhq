# frozen_string_literal: true

FactoryBot.define do
  factory :service_desk_custom_email_verification, class: '::ServiceDesk::CustomEmailVerification' do
    state { 'started' }
    token { 'XXXXXXXXXXXX' }
    project
    triggerer factory: :user
    triggered_at { Time.current }
  end
end
