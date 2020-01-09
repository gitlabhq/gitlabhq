# frozen_string_literal: true

FactoryBot.define do
  factory :chat_name, class: 'ChatName' do
    user factory: :user
    service factory: :service

    team_id { 'T0001' }
    team_domain { 'Awesome Team' }

    sequence(:chat_id) { |n| "U#{n}" }
    chat_name { generate(:username) }
  end
end
