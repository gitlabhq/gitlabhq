# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    access_level { Gitlab::Access::GUEST }
    source { association(:source) }
    member_namespace_id { source.id }
    user

    trait(:guest) { access_level { Gitlab::Access::GUEST } }
    trait(:planner) { access_level { Gitlab::Access::PLANNER } }
    trait(:reporter) { access_level { Gitlab::Access::REPORTER } }
    trait(:developer) { access_level { Gitlab::Access::DEVELOPER } }
    trait(:maintainer) { access_level { Gitlab::Access::MAINTAINER } }
    trait(:owner) { access_level { Gitlab::Access::OWNER } }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user { nil }
      invite_token { 'xxx' }
      sequence :invite_email do |n|
        "email#{n}@email.com"
      end
    end

    trait :blocked do
      after(:build) { |member, _| member.user.block! }
    end

    trait :awaiting do
      after(:create) do |member|
        member.update!(state: ::Member::STATE_AWAITING)
      end
    end

    trait :active do
      after(:create) do |member|
        member.update!(state: ::Member::STATE_ACTIVE)
      end
    end
  end
end
