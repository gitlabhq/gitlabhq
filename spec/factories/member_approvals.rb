# frozen_string_literal: true

FactoryBot.define do
  factory :member_approval, class: 'Members::MemberApproval' do
    requested_by { association(:user) }
    reviewed_by { association(:user) }
    old_access_level { ::Gitlab::Access::GUEST }
    new_access_level { ::Gitlab::Access::DEVELOPER }
    status { ::Members::MemberApproval.statuses[:pending] }
    member { association(:project_member) } # default
    member_namespace_id { member.member_namespace_id }

    # Traits for specific group members
    trait :for_group_member do
      member { association(:group_member) }
    end

    trait :for_project_member do
      member { association(:project_member) }
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
