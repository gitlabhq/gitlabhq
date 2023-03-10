# frozen_string_literal: true

FactoryBot.define do
  factory :service_desk_custom_email_verification, class: '::ServiceDesk::CustomEmailVerification' do
    project
    state { "running" }
  end
end
