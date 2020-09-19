# frozen_string_literal: true

FactoryBot.define do
  factory :authentication_event do
    user
    provider { :standard }
    user_name { 'Jane Doe' }
    ip_address { '127.0.0.1' }
    result { :failed }
  end
end
