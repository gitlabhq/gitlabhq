FactoryBot.define do
  factory :group, class: Group, parent: :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type 'Group'
    owner nil
    project_creation_level ::EE::Gitlab::Access::MASTER_PROJECT_ACCESS

    after(:create) do |group|
      if group.owner
        # We could remove this after we have proper constraint:
        # https://gitlab.com/gitlab-org/gitlab-ce/issues/43292
        raise "Don't set owner for groups, use `group.add_owner(user)` instead"
      end
    end

    after(:create) do |group|
      if group.owner
        # We could remove this after we have proper constraint:
        # https://gitlab.com/gitlab-org/gitlab-ce/issues/43292
        raise "Don't set owner for groups, use `group.add_owner(user)` instead"
      end
    end

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end

    factory :group_with_members do
      after(:create) do |group, evaluator|
        group.add_developer(create :user)
      end
    end

    factory :group_with_ldap do
      transient do
        cn 'group1'
        group_access Gitlab::Access::GUEST
        provider 'ldapmain'
      end

      factory :group_with_ldap_group_link do
        after(:create) do |group, evaluator|
          group.ldap_group_links << create(
            :ldap_group_link,
              cn: evaluator.cn,
              group_access: evaluator.group_access,
              provider: evaluator.provider
          )
        end
      end

      factory :group_with_ldap_group_filter_link do
        after(:create) do |group, evaluator|
          group.ldap_group_links << create(
            :ldap_group_link,
              filter: '(a=b)',
              cn: nil,
              group_access: evaluator.group_access,
              provider: evaluator.provider
          )
        end
      end
    end

    trait :access_requestable do
      request_access_enabled true
    end

    trait :nested do
      parent factory: :group
    end
  end
end
