# frozen_string_literal: true

FactoryBot.define do
  factory :service_desk_custom_email_credential, class: '::ServiceDesk::CustomEmailCredential' do
    project
    smtp_address { "smtp.example.com" }
    smtp_username { "user@example.com" }
    smtp_port { 587 }
    smtp_password { "supersecret" }
  end
end
