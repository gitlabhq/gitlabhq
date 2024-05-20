# frozen_string_literal: true

FactoryBot.define do
  factory :group_member do
    access_level { GroupMember::OWNER }
    source { association(:group) }
    member_namespace_id { source.id }
    user

    trait(:guest)     { access_level { GroupMember::GUEST } }
    trait(:reporter)  { access_level { GroupMember::REPORTER } }
    trait(:developer) { access_level { GroupMember::DEVELOPER } }
    trait(:maintainer) { access_level { GroupMember::MAINTAINER } }
    trait(:owner) { access_level { GroupMember::OWNER } }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user { nil }
      invite_token { 'xxx' }
      sequence :invite_email do |n|
        "email#{n}@email.com"
      end
    end

    trait(:ldap) do
      ldap { true }
    end

    trait :blocked do
      after(:build) { |group_member, _| group_member.user.block! }
    end

    trait :banned do
      after(:create) do |member|
        create(:namespace_ban, namespace: member.member_namespace.root_ancestor, user: member.user) unless member.owner?
      end
    end

    trait :minimal_access do
      to_create { |instance| instance.save!(validate: false) }

      access_level { GroupMember::MINIMAL_ACCESS }
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
