# frozen_string_literal: true

FactoryBot.define do
  factory :user_status do
    user
    emoji { 'coffee' }
    message { 'I crave coffee' }
  end
end
