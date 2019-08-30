# frozen_string_literal: true

FactoryBot.define do
  factory :group_member do
    access_level { GroupMember::OWNER }
    group
    user

    trait(:guest)     { access_level GroupMember::GUEST }
    trait(:reporter)  { access_level GroupMember::REPORTER }
    trait(:developer) { access_level GroupMember::DEVELOPER }
    trait(:maintainer) { access_level GroupMember::MAINTAINER }
    trait(:owner) { access_level GroupMember::OWNER }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user_id nil
      invite_token 'xxx'
      sequence :invite_email do |n|
        "email#{n}@email.com"
      end
    end

    trait(:ldap) do
      ldap true
    end

    trait :blocked do
      after(:build) { |group_member, _| group_member.user.block! }
    end
  end
end
