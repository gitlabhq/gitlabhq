FactoryBot.define do
  factory :group, class: Group, parent: :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type 'Group'
    owner nil

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

    trait :access_requestable do
      request_access_enabled true
    end

    trait :nested do
      parent factory: :group
    end
  end
end
