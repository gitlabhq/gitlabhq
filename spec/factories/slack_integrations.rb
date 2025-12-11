# frozen_string_literal: true

FactoryBot.define do
  factory :slack_integration do
    sequence(:team_id) { |n| "T123#{n}" }
    sequence(:user_id) { |n| "U123#{n}" }
    sequence(:bot_user_id) { |n| "U123#{n}" }
    sequence(:bot_access_token) { |n| OpenSSL::Digest::SHA256.hexdigest(n.to_s) }
    sequence(:team_name) { |n| "team#{n}" }
    sequence(:alias) { |n| "namespace#{n}/project_name#{n}" }

    organization { association :common_organization }
    integration { association :gitlab_slack_application_integration, slack_integration: instance }

    trait :legacy do
      bot_user_id { nil }
      bot_access_token { nil }
    end

    trait :instance do
      organization { association :common_organization }
      group { nil }
      project { nil }
      integration { association :gitlab_slack_application_integration, :instance, slack_integration: instance }
    end

    trait :group do
      organization { nil }
      group
      project { nil }
      integration { association :gitlab_slack_application_integration, :group, slack_integration: instance }
    end

    trait :project do
      organization { nil }
      group { nil }
      project
    end

    trait :all_features_supported do
      after(:build) do |slack_integration, _evaluator|
        slack_integration.authorized_scope_names = %w[commands chat:write chat:write.public]
      end
    end
  end
end
