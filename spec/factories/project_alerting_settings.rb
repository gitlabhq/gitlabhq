# frozen_string_literal: true

FactoryBot.define do
  factory :project_alerting_setting, class: 'Alerting::ProjectAlertingSetting' do
    project
    token { SecureRandom.hex }

    # Remove in next required stop after %16.4
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338838
    transient do
      sync_http_integrations { false }
    end

    trait :with_http_integration do
      sync_http_integrations { true }
    end

    # for simplicity, let factory exclude the AlertManagement::HttpIntegration
    # created in after_commit callback on model
    after(:create) do |setting, evaluator|
      next if evaluator.sync_http_integrations

      setting.project.alert_management_http_integrations.last!.destroy!
    end
  end
end
