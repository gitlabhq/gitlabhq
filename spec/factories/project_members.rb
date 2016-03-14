FactoryGirl.define do
  factory :project_member do
    user
    project
    master

    trait :guest do
      access_level ProjectMember::GUEST
    end

    trait :reporter do
      access_level ProjectMember::REPORTER
    end

    trait :developer do
      access_level ProjectMember::DEVELOPER
    end

    trait :master do
      access_level ProjectMember::MASTER
    end

    trait :owner do
      access_level ProjectMember::OWNER
    end
  end
end
