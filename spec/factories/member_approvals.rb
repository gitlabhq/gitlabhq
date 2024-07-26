# frozen_string_literal: true

FactoryBot.define do
  factory :member_approval, class: 'Members::MemberApproval' do
    requested_by { association(:user) }
    reviewed_by { association(:user) }
    user { association(:user) }
    old_access_level { ::Gitlab::Access::GUEST }
    new_access_level { ::Gitlab::Access::DEVELOPER }
    status { ::Members::MemberApproval.statuses[:pending] }
    member { association(:project_member, user: user) }
    member_namespace { association(:namespace) }
    member_role_id { nil }
    metadata { { access_level: new_access_level, member_role_id: member_role_id }.compact }

    trait :for_new_member do
      member { nil }
      old_access_level { nil }
    end

    trait :for_group_member do
      member { association(:group_member, user: user) }
      member_namespace { member.member_namespace }
    end

    trait :for_project_member do
      member { association(:project_member, user: user) }
      member_namespace { member.member_namespace }
    end

    trait(:guest)     { old_access_level { GroupMember::GUEST } }
    trait(:reporter)  { old_access_level { GroupMember::REPORTER } }
    trait(:developer) { old_access_level { GroupMember::DEVELOPER } }
    trait(:maintainer) { old_access_level { GroupMember::MAINTAINER } }
    trait(:owner) { old_access_level { GroupMember::OWNER } }

    trait(:to_guest)     { new_access_level { GroupMember::GUEST } }
    trait(:to_reporter)  { new_access_level { GroupMember::REPORTER } }
    trait(:to_developer) { new_access_level { GroupMember::DEVELOPER } }
    trait(:to_maintainer) { new_access_level { GroupMember::MAINTAINER } }
    trait(:to_owner) { new_access_level { GroupMember::OWNER } }
  end
end
