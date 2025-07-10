# frozen_string_literal: true

FactoryBot.define do
  factory :observability_group_o11y_setting, class: 'Observability::GroupO11ySetting' do
    group
    o11y_service_url { 'https://example.com' }
    o11y_service_user_email { 'test@example.com' }
    o11y_service_password { 'password' }
    o11y_service_post_message_encryption_key { 'secret_key' }
  end
end
