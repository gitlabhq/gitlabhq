# frozen_string_literal: true

FactoryBot.define do
  factory :user_agent_detail do
    ip_address { '127.0.0.1' }
    user_agent { 'AppleWebKit/537.36' }
    association :subject, factory: :issue
  end
end
