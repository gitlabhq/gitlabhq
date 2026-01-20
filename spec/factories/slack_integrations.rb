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
      group_id { nil }
      project_id { nil }
      integration do
        association(
          :gitlab_slack_application_integration, :instance, slack_integration: instance, organization: organization
        )
      end
    end

    trait :group do
      organization_id { nil }
      group
      project_id { nil }
      integration do
        association(:gitlab_slack_application_integration, :group, slack_integration: instance, group: group)
      end
    end

    trait :project do
      organization_id { nil }
      group_id { nil }
      project
      integration { association :gitlab_slack_application_integration, slack_integration: instance, project: project }
    end

    trait :all_features_supported do
      after(:build) do |slack_integration, _evaluator|
        slack_integration.authorized_scope_names = %w[commands chat:write chat:write.public]
      end
    end

    # Ensure the correct sharding key is set at build time, before the instance
    # is passed to the :gitlab_slack_application_integration factory.
    after(:build) do |slack_integration, _evaluator|
      slack_integration.organization_id = slack_integration.organization.id if slack_integration.organization
      slack_integration.group_id = slack_integration.group.id if slack_integration.group
      slack_integration.project_id = slack_integration.project.id if slack_integration.project
    end
  end
end
