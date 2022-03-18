# frozen_string_literal: true

FactoryBot.define do
  factory :saved_reply, class: 'Users::SavedReply' do
    sequence(:name) { |n| "saved_reply_#{n}" }
    content { 'Saved Reply Content' }

    user
  end
end
