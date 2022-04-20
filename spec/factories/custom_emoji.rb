# frozen_string_literal: true

FactoryBot.define do
  factory :custom_emoji, class: 'CustomEmoji' do
    sequence(:name) { |n| "custom_emoji#{n}" }
    group
    file { 'https://gitlab.com/images/partyparrot.png' }
    creator factory: :user
  end
end
