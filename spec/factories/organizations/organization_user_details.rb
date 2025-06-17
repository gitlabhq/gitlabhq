# frozen_string_literal: true

FactoryBot.define do
  factory :organization_user_detail, class: 'Organizations::OrganizationUserDetail' do
    user
    organization

    sequence(:username) { |n| "user_alias_#{n}" }
    display_name { username.humanize.titleize }
  end
end
