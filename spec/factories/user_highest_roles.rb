# frozen_string_literal: true

FactoryBot.define do
  factory :user_highest_role do
    highest_access_level { nil }
    user

    trait(:guest)          { highest_access_level { GroupMember::GUEST } }
    trait(:planner)        { highest_access_level { GroupMember::PLANNER } }
    trait(:reporter)       { highest_access_level { GroupMember::REPORTER } }
    trait(:developer)      { highest_access_level { GroupMember::DEVELOPER } }
    trait(:maintainer)     { highest_access_level { GroupMember::MAINTAINER } }
    trait(:owner)          { highest_access_level { GroupMember::OWNER } }
  end
end
