# frozen_string_literal: true

FactoryBot.define do
  factory :chat_team, class: 'ChatTeam' do
    sequence(:team_id) { |n| "abcdefghijklm#{n}" }
    namespace factory: :group
  end
end
