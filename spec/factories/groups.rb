FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type 'Group'

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end

    factory :group_with_members do
      after(:create) do |group, evaluator|
        group.add_developer(create :user)
      end
    end

    factory :group_with_ldap_group_link do
      transient do
        cn 'group1'
        group_access Gitlab::Access::GUEST
        provider 'ldapmain'
      end

      after(:create) do |group, evaluator|
        group.ldap_group_links << create(
          :ldap_group_link,
          cn: evaluator.cn,
          group_access: evaluator.group_access,
          provider: evaluator.provider
        )
      end
    end
  end
end
