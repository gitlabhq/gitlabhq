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
      invite_email 'email@email.com'
    end
  end
end
