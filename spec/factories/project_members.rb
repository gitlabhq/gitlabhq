# frozen_string_literal: true

FactoryBot.define do
  factory :project_member do
    user
    source { association(:project) }
    maintainer

    trait(:guest)     { access_level { ProjectMember::GUEST } }
    trait(:reporter)  { access_level { ProjectMember::REPORTER } }
    trait(:developer) { access_level { ProjectMember::DEVELOPER } }
    trait(:maintainer) { access_level { ProjectMember::MAINTAINER } }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user_id { nil }
      invite_token { 'xxx' }
      sequence :invite_email do |n|
        "email#{n}@email.com"
      end
    end

    trait :blocked do
      after(:build) { |project_member, _| project_member.user.block! }
    end
  end
end
