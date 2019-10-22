# frozen_string_literal: true

FactoryBot.define do
  factory :grafana_integration, class: GrafanaIntegration do
    project
    grafana_url { 'https://grafana.com' }
    token { SecureRandom.hex(10) }
  end
end
