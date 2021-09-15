# frozen_string_literal: true

FactoryBot.define do
  factory :group_callout, class: 'Users::GroupCallout' do
    feature_name { :invite_members_banner }

    user
    group
  end
end
