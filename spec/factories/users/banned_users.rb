# frozen_string_literal: true

FactoryBot.define do
  factory :banned_user, class: 'Users::BannedUser' do
    user { association(:user) }
  end
end
