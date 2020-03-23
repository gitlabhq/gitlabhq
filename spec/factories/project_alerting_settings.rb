# frozen_string_literal: true

FactoryBot.define do
  factory :project_alerting_setting, class: 'Alerting::ProjectAlertingSetting' do
    project
    token { 'access_token_123' }
  end
end
