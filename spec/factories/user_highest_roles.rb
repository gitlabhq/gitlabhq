# frozen_string_literal: true

FactoryBot.define do
  factory :user_highest_role do
    user

    trait :maintainer do
      highest_access_level { Gitlab::Access::MAINTAINER }
    end

    trait :developer do
      highest_access_level { Gitlab::Access::DEVELOPER }
    end
  end
end
