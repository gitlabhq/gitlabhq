# frozen_string_literal: true

FactoryBot.define do
  factory :operations_strategy, class: 'Operations::FeatureFlags::Strategy' do
    association :feature_flag, factory: :operations_feature_flag
    name { "default" }
    parameters { {} }

    trait :default do
      name { "default" }
      parameters { {} }
    end

    trait :gitlab_userlist do
      association :user_list, factory: :operations_feature_flag_user_list
      name { "gitlabUserList" }
      parameters { {} }
    end

    trait :flexible_rollout do
      name { "flexibleRollout" }
      parameters do
        {
          groupId: 'default',
          rollout: '10',
          stickiness: 'default'
        }
      end
    end

    trait :gradual_rollout do
      name { "gradualRolloutUserId" }
      parameters { { percentage: '10', groupId: 'default' } }
    end

    trait :userwithid do
      name { "userWithId" }
      parameters { { userIds: 'user1' } }
    end
  end
end
